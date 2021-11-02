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
	TongTien money not null default 0 CHECK (TongTien >= 0)
	CONSTRAINT PK_HoaDon  PRIMARY KEY(MaHD)
)
CREATE TABLE CT_HoaDon
(
	MaHD int not null,
	MaSP int not null,
	SoLuong int not null default 0 CHECK (SoLuong >= 0),
	GiaBan money not null default 0 CHECK (GiaBan >= 0),
	GiaGiam money not null default 0 CHECK (GiaGiam >= 0),
	ThanhTien money not null default 0 CHECK (ThanhTien >= 0),
	CONSTRAINT PK_CT_HoaDon PRIMARY KEY(MaHD, MaSP)
)
CREATE TABLE SanPham
(
	MaSP int not null IDENTITY,
	TenSP nvarchar(100),
	SoLuongTon smallint CHECK (SoLuongTon >= 0),
	Mota nvarchar(max),
	Gia money not null default 0 CHECK (Gia >= 0)
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
-- TRIGGER --
a. Thành tiền CTHD = (Số lượng * (Giá bán - Giá giảm))
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

--------------------------------------------

CÀI TRIGGER CHO BẢNG HOADON
(Insert)
Ràng buộc: 
	-	tongtien của một hoadon vừa insert phải bằng 0 (vì chưa có ct_hoadon)
Thực hiện:
	-	Kiểm tra ràng buộc. Nếu sai, rollback
*/
GO
CREATE TRIGGER tg_HoaDon_Insert ON HoaDon 
	AFTER INSERT
AS
	IF EXISTS (SELECT * FROM INSERTED i WHERE i.TongTien != 0)
	BEGIN
		RAISERROR('Ban da insert mot hoadon co tongtien khac 0', 0, 1)
		ROLLBACK
	END
GO

/*
(Update)
Ràng buộc: 
	-	tongtien của hoadon được update phải bằng tổng các thành tiền của các ct_hoadon tương ứng
Thực hiện
	-	Kiểm tra ràng buộc. Nếu sai, rollback
*/
CREATE TRIGGER tg_HoaDon_Update ON HoaDon
	AFTER UPDATE
AS
	IF (UPDATE(TongTien))
	BEGIN
		IF EXISTS (SELECT * 
				   FROM INSERTED i LEFT JOIN CT_HoaDon ct ON i.MaHD = ct.MaHD
				   GROUP BY i.MaHD, i.TongTien
				   HAVING i.TongTien != COALESCE(SUM(ct.thanhtien), 0))
		BEGIN
			RAISERROR('Update hoadon co tongtien khong bang tong thantien cua cac ct_hoadon tuong ung', 15, 1)
			ROLLBACK
		END
	END
GO

/*
CÀI TRIGGER CHO CT_HOADON
(Insert | Update)
Ràng buộc:
	-	giaban = gia(sanpham)						
	-	thanhtien = soluong * (giaban - giagiam)	 
	-	tongtien(hoadon) = sum(thanhtien) 
Thực hiện:
	-	Nếu là insert: cập nhật thông tin giaban, giagiam, thanhtien, tongtien(hoadon)
	-	Nếu là update: cập nhật lại thông tin giaban, thanhtien, tongtien(hoadon)	
*/
CREATE TRIGGER tg_CtHoaDon_Insert_Update ON CT_HoaDon
	AFTER INSERT, UPDATE
AS
	-- Xét hành động INSERT (chỉ có insert thì bảng deleded mới rỗng)
	IF NOT EXISTS (SELECT * FROM DELETED) 
	BEGIN  
		-- Update lại giaban từ gia(sanpham)
    	UPDATE CT_HoaDon
			SET CT_HoaDon.GiaBan = (SELECT sp.Gia FROM SanPham sp WHERE sp.MaSP = CT_HoaDon.MaSP)
			WHERE EXISTS (SELECT * FROM INSERTED i WHERE i.MaHD = CT_HoaDon.MaHD AND i.MaSP = CT_HoaDon.MaSP)
		-- Tạo giagiam (bằng 0%, 5%, 10% giaban), update thanhtien = soluong * (giaban - giagiam)
		UPDATE CT_HoaDon
			SET CT_HoaDon.GiaGiam = CT_HoaDon.GiaBan * (FLOOR(RAND() * 3) * 5) / 100
			WHERE EXISTS (SELECT * FROM INSERTED i WHERE i.MaHD = CT_HoaDon.MaHD AND i.MaSP = CT_HoaDon.MaSP)
		UPDATE CT_HoaDon
			SET ct_hoadon.ThanhTien = ct_hoadon.SoLuong * (ct_hoadon.GiaBan - ct_hoadon.GiaGiam)
			WHERE EXISTS (SELECT * FROM INSERTED i WHERE i.MaHD = CT_HoaDon.MaHD AND i.MaSP = CT_HoaDon.MaSP)
		-- Update tongtien(hoadon)
		UPDATE HoaDon 
			SET HoaDon.TongTien = (SELECT COALESCE(SUM(ct.ThanhTien), 0)
							   	       FROM CT_HoaDon ct
									   WHERE ct.MaHD = HoaDon.MaHD)
			WHERE HoaDon.mahd IN (SELECT i.mahd FROM INSERTED i)
    END
	
	-- Xét hành động UPDATE
    ELSE
	BEGIN
		-- Nếu có thay đổi các thông tin liên quan đến thanhtien thì tính lại số liệu 
		IF UPDATE(giaban) OR UPDATE(masp) OR UPDATE(soluong) OR UPDATE(giagiam) OR UPDATE(thanhtien)
		BEGIN
			-- Nếu có thay đổi tại giaban hoặc masp -> update lại giaban phù hợp
			IF UPDATE(GiaBan) OR UPDATE(MaSP)
			BEGIN
				UPDATE CT_HoaDon
					SET CT_HoaDon.GiaBan = (SELECT sp.Gia FROM SanPham sp WHERE sp.MaSP = CT_HoaDon.MaSP)
					WHERE EXISTS (SELECT * FROM INSERTED i WHERE i.MaHD = CT_HoaDon.MaHD AND i.MaSP = CT_HoaDon.MaSP)
			END
			-- Update thanhtien
			UPDATE CT_HoaDon
				SET ThanhTien = SoLuong * (GiaBan - GiaGiam)
				WHERE EXISTS (SELECT * FROM INSERTED i WHERE i.MaHD = CT_HoaDon.MaHD AND i.MaSP = CT_HoaDon.MaSP)
        END		
		-- Update lại tongtien(hoadon)
		UPDATE HoaDon 
			SET HoaDon.TongTien = (SELECT COALESCE(SUM(ct.ThanhTien), 0) 
								       FROM CT_HoaDon ct 
									   WHERE ct.MaHD = HoaDon.MaHD)
			WHERE HoaDon.mahd IN (SELECT D.mahd FROM DELETED d) OR HoaDon.mahd IN (SELECT i.MaHD FROM INSERTED i)
	END
GO

/*
(Delete)
Ràng buộc: 
	-	khi xoá một ct_hoadon, tongtien của hoadon tương ứng trừ đi thanhtien
Thực hiện:
	-	Cập nhật tongtien của hoadon tương ứng với ct_hoadon được xoá
*/
CREATE TRIGGER tg_CTHoaDon_Delete ON CT_HoaDon 
	AFTER DELETE
AS
	UPDATE HoaDon
		SET HoaDon.TongTien -= (SELECT SUM(D.ThanhTien) FROM DELETED d WHERE D.MaHD = HoaDon.MaHD)
		WHERE HoaDon.mahd IN (SELECT D.MaHD FROM DELETED d)
GO
