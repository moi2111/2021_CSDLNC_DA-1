CREATE DATABASE QLBH
GO
USE QLBH
GO

-- TẠO BẢNG VÀ RÀNG BUỘC KHÓA CHÍNH
CREATE TABLE KhachHang
(
	MaKH int not null IDENTITY,
	Ho nvarchar(30),
	Ten nvarchar(30),
	Ngsinh datetime,
	SoNha varchar(15),
	Duong nvarchar(50),
	Phuong nvarchar(50),
	Quan nvarchar(50),
	Tpho nvarchar(50),
	DienThoai char(15) UNIQUE,
	CONSTRAINT PK_KhachHang PRIMARY KEY(MaKH)
)
CREATE TABLE HoaDon
(
	MaHD int not null IDENTITY(1,1),
	MaKH int,
	NgayLap datetime,
	TongTien bigint not null default 0 CHECK (TongTien >= 0)
	CONSTRAINT PK_HoaDon  PRIMARY KEY(MaHD)
)
CREATE TABLE CT_HoaDon
(
	MaHD int not null,
	MaSP int not null,
	SoLuong int not null default 0 CHECK (SoLuong >= 0),
	GiaBan int not null default 0 CHECK (GiaBan >= 0),
	GiaGiam int not null default 0 CHECK (GiaGiam >= 0),
	ThanhTien bigint not null default 0 CHECK (ThanhTien >= 0),
	CONSTRAINT PK_CT_HoaDon PRIMARY KEY(MaHD, MaSP)
)
CREATE TABLE SanPham
(
	MaSP int not null IDENTITY,
	TenSP nvarchar(100),
	SoLuongTon smallint CHECK (SoLuongTon >= 0),
	Mota nvarchar(max),
	Gia int not null default 0 CHECK (Gia >= 0)
	CONSTRAINT PK_SanPham PRIMARY KEY(MaSP)
)
GO

--TẠO RÀNG BUỘC KHÓA NGOẠI
ALTER TABLE HoaDon
ADD
	CONSTRAINT FK_HoaDon_KhachHang
	FOREIGN KEY(MaKH)
	REFERENCES KhachHang(MaKH)

ALTER TABLE CT_HoaDon
ADD
	CONSTRAINT FK_CT_HoaDon_HoaDon FOREIGN KEY(MaHD) REFERENCES HoaDon(MaHD),
	CONSTRAINT FK_CT_HoaDon_SanPham FOREIGN KEY(MaSP) REFERENCES SanPham(MaSP)
GO

/*
					TRIGGER
a/ Thành tiền CTHD = (Số lượng * (Giá bán - Giá giảm))
Bảng TAH:
			|	T	|	X	|	S
____________|_______|_______|___________________________________
CT_HoaDon	|	+	|	-	|	+ (SoLuong,GiaBan,GiaGiam,ThanhTien)

b. Tổng tiền trong hóa đơn = tổng thanh toán từng chi tiết hóa đơn
Bảng TAH:
			|	T	|	X	|	S
____________|_______|_______|________________________________________
HoaDon		|	+	|	-	|	+ (TongTien)
____________|_______|_______|________________________________________
CT_HoaDon	|	+	|	+	|	+ (MaSP,SoLuong,GiaBan,GiaGiam,ThanhTien)


* CÀI TRIGGER CHO BẢNG HOADON
(INSERT)
Ràng buộc: 
	-	tongtien của một hoadon vừa insert phải bằng 0 (vì chưa có ct_hoadon)
Thực hiện:
	-	Kiểm tra ràng buộc. Nếu có một hoadon có tongtien khác 0 => ROLLBACK
*/
CREATE TRIGGER tg_HoaDon_Insert ON HoaDon 
	AFTER INSERT
AS
	IF EXISTS (SELECT * FROM INSERTED i WHERE i.TongTien != 0)
	BEGIN
		RAISERROR('Loi: Insert mot hoadon co tongtien khac 0', 0, 1)
		ROLLBACK
	END
GO

/*
(UPDATE)
Ràng buộc: 
	-	tongtien của hoadon được update phải bằng tổng các thành tiền của các ct_hoadon tương ứng
Thực hiện
	-	Kiểm tra ràng buộc. Nếu sai, rollback
*/
CREATE TRIGGER tg_HoaDon_Update ON HoaDon
	AFTER UPDATE
AS
	IF (UPDATE(TongTien) OR UPDATE(MaHD))
	BEGIN
		IF EXISTS (SELECT * 
				   FROM INSERTED i LEFT JOIN CT_HoaDon ct ON i.MaHD = ct.MaHD
				   GROUP BY i.MaHD, i.TongTien
				   HAVING i.TongTien != COALESCE(SUM(ct.thanhtien), 0))
		BEGIN
			RAISERROR('Loi: Update hoadon co tongtien khong bang tong thantien cua cac ct_hoadon tuong ung', 15, 1)
			ROLLBACK
		END
	END
GO

/*
CÀI TRIGGER CHO CT_HOADON
(INSERT)
Ràng buộc liên quan:
	- Với mỗi ct_hoadon: thanhtien = soluong * (giaban - giagiam)
	- Tongtien(hoadon) = tổng các thanhtien của các ct_hoadon có mahd của nó
Thực hiện:
	- Kiểm tra ràng buộc: thanhtien = soluong * (giaban - giagiam)
	- Update tongtien(hoadon)
*/

CREATE TRIGGER tg_CtHoaDon_Insert ON CT_HoaDon
	AFTER INSERT
AS
	IF EXISTS (SELECT * FROM INSERTED i JOIN SanPham sp ON i.MaSP = sp.MaSP AND i.GiaBan != sp.Gia)
	BEGIN  
    	RAISERROR('Loi: Insert CT_HoaDon co giaban khong khop voi gia cua sanpham', 15, 1)
		ROLLBACK
    END
    
   	IF EXISTS (SELECT * FROM INSERTED i WHERE i.ThanhTien != i.SoLuong * (i.GiaBan - i.GiaGiam))
	BEGIN  
   		RAISERROR('Loi: Insert ct_hoadon co thanhtien != soluong * (giaban - giagiam)', 15, 1)
		ROLLBACK
	END

	UPDATE HoaDon 
			SET HoaDon.TongTien = (SELECT COALESCE(SUM(ct.ThanhTien), 0)
							   	       FROM CT_HoaDon ct
									   WHERE ct.MaHD = HoaDon.MaHD)
			WHERE HoaDon.mahd IN (SELECT i.mahd FROM INSERTED i)
GO

/*
(UPDATE)
Ràng buộc liên quan:
	- Với mỗi ct_hoadon: thanhtien = soluong * (giaban - giagiam)
	- Tongtien(hoadon) = tổng các thanhtien của các ct_hoadon có mahd của nó
Thực hiện:
	- Nếu có thay đổi liên quan đến <masp>: không cho thực hiện, rollback
	- Nếu có thay đổi liên quan đến <thanhtien, soluong, giaban, giagiam>: kiểm tra 
	  ràng buộc thanhtien = soluong * (giaban - giagiam), nếu sai thì rollback
	- Update lại tongtien trong ban hoadon: tongtien(hoadon) = tổng các thanhtien của các ct_hoadon có mahd của nó
*/
CREATE TRIGGER tg_CtHoaDon_Update ON CT_HoaDon
	AFTER UPDATE
AS     
	IF UPDATE(MaSP)
	BEGIN
		RAISERROR('Khong duoc thay doi MaHD hay MaSP cua CT_HoaDon', 15, 1)
		ROLLBACK
	END
	IF UPDATE(ThanhTien) OR UPDATE(SoLuong) OR UPDATE(GiaBan) OR UPDATE(GiaGiam) 
	BEGIN
		IF EXISTS (SELECT * FROM INSERTED i WHERE i.ThanhTien != i.SoLuong * (i.GiaBan - i.GiaGiam))
		BEGIN  
   			RAISERROR('Loi: Update ct_hoadon co thanhtien != soluong * (giaban - giagiam)', 15, 1)
			ROLLBACK
		END
	END
	UPDATE HoaDon 
			SET HoaDon.TongTien = (SELECT COALESCE(SUM(ct.ThanhTien), 0) 
								       FROM CT_HoaDon ct 
									   WHERE ct.MaHD = HoaDon.MaHD)
			WHERE HoaDon.mahd IN (SELECT D.mahd FROM DELETED d) OR HoaDon.mahd IN (SELECT i.MaHD FROM INSERTED i)
GO

/*
(DELETE)
Ràng buộc liên quan:
	- Tongtien(hoadon) = tổng các thanhtien của các ct_hoadon có mahd của nó
Thực hiện:
	- Update lại tongtien trong ban hoadon: tongtien(hoadon) = tổng các thanhtien của các ct_hoadon có mahd của nó 
*/
CREATE TRIGGER tg_CtHoaDon ON CT_HoaDon
	AFTER DELETE
AS
	UPDATE HoaDon
		SET HoaDon.TongTien -= (SELECT SUM(D.ThanhTien) FROM DELETED d WHERE D.MaHD = HoaDon.MaHD)
		WHERE HoaDon.mahd IN (SELECT D.MaHD FROM DELETED d)
GO



-- CÀI PROCEDURE LIÊN QUAN
-- Procedure cho hành động insert 
CREATE PROCEDURE sp_Insert_CtHoaDon @mahd int, @masp int, @soluong int
AS 
	DECLARE @giaban int, 
		@giagiam int, 	
		@thanhtien int
	SELECT @giaban = sp.Gia FROM SanPham sp WHERE sp.MaSP = @masp
	SET @giagiam = @giaban * (FLOOR(RAND() * 3) * 5) / 100
	SET @thanhtien = @soluong * (@giaban - @giagiam)
	INSERT INTO CT_HoaDon (MaHD, MaSP, SoLuong, GiaBan, GiaGiam, ThanhTien) 
		VALUES (@mahd, @masp, @soluong, @giaban, @giagiam, @thanhtien)
GO
