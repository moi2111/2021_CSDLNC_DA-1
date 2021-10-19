USE master
GO
IF DB_ID('QLBH') IS NOT NULL
	DROP DATABASE QLBH
GO
CREATE DATABASE QLBH
GO
USE QLBH
GO

--TẠO BẢNG VÀ RÀNG BUỘC KHÓA CHÍNH
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
	DienThoai char(15)
	CONSTRAINT PK_KhachHang
	PRIMARY KEY(MaKH)
)
CREATE TABLE HoaDon
(
	MaHD int not null IDENTITY(1,1),
	MaKH int,
	NgayLap datetime,
	TongTien money not null default 0
	CONSTRAINT PK_HoaDon
	PRIMARY KEY(MaHD)
)
CREATE TABLE CT_HoaDon
(
	MaHD int not null,
	MaSP int not null,
	SoLuong int not null default 0,
	GiaBan money not null default 0,
	GiaGiam money not null default 0,
	ThanhTien money not null default 0
	CONSTRAINT PK_CT_HoaDon
	PRIMARY KEY(MaHD, MaSP)
)
CREATE TABLE SanPham
(
	MaSP int not null IDENTITY,
	TenSP nvarchar(100),
	SoLuongTon smallint,
	Mota nvarchar(max),
	Gia money not null default 0
	CONSTRAINT PK_SanPham
	PRIMARY KEY(MaSP)
)

--TẠO RÀNG BUỘC KHÓA NGOẠI
ALTER TABLE HoaDon
ADD
	CONSTRAINT FK_HoaDon_KhachHang
	FOREIGN KEY(MaKH)
	REFERENCES KhachHang(MaKH)

ALTER TABLE CT_HoaDon
ADD
	CONSTRAINT FK_CT_HoaDon_HoaDon
	FOREIGN KEY(MaHD)
	REFERENCES HoaDon(MaHD),
	CONSTRAINT FK_CT_HoaDon_SanPham
	FOREIGN KEY(MaSP)
	REFERENCES SanPham(MaSP)

ALTER TABLE KhachHang
ADD
	CONSTRAINT U_DienThoai UNIQUE(DienThoai)

--STORED PROCEDURE
GO
CREATE PROCEDURE sp_updateCT_HoaDon
AS--UPDATE(GiaBan,GiaGiam)
	IF(EXISTS(SELECT * FROM CT_HoaDon CT, SanPham SP WHERE CT.MaSP = SP.MaSP))
	BEGIN
		DECLARE @MaSP int, @GiaBan money, @GiaGiam money, @Min int, @Max int
		SELECT @MaSP = CT.MaSP, @GiaBan = SP.Gia
				FROM CT_HoaDon CT, SanPham SP WHERE CT.MaSP = SP.MaSP
		SET @Min = 1
		SET @Max = 10
		SET @GiaGiam = (@GiaBan * FLOOR(RAND()*(@Max-@Min+1)+@Min)) / 100
		UPDATE CT_HoaDon
		SET GiaBan = @GiaBan, GiaGiam = @GiaGiam
		WHERE MaSP = @MaSP
	END

--TRIGGER
/*a. Thành tiền CTHD = (Số lượng * (Giá bán - Giá giảm))
Bảng TAH:
			|	T	|	X	|		S
____________|_______|_______|___________________________________
CT_HoaDon	|	+	|	-	|+(SoLuong,GiaBan,GiaGiam,ThanhTien)
*/
GO
CREATE TRIGGER tg_CapNhatThanhTien ON CT_HoaDon FOR INSERT, UPDATE
AS
	IF (UPDATE(SoLuong) OR UPDATE(GiaBan) OR UPDATE(GiaGiam) OR UPDATE(ThanhTien))
	BEGIN
		UPDATE CT_HoaDon
		SET ThanhTien = SoLuong * (GiaBan - GiaGiam)
		WHERE EXISTS(SELECT * FROM INSERTED I
				WHERE I.MaHD = CT_HoaDon.MaHD AND I.MaSP = CT_HoaDon.MaSP)
	END

/*b. Tổng tiền trong hóa đơn = tổng thanh toán từng chi tiết hóa đơn
Bảng TAH:
			|	T	|	X	|		S
____________|_______|_______|________________________________________
HoaDon		|	-	|	-	|+(TongTien)
____________|_______|_______|________________________________________
CT_HoaDon	|	+	|	+	|+(MaSP,SoLuong,GiaBan,GiaGiam,ThanhTien)
*/

GO
CREATE TRIGGER tg_HoaDon_update ON HoaDon AFTER UPDATE
AS
	DECLARE @TongTien money
	DECLARE @MaHD int
	SELECT @MaHD = MaHD, @TongTien = TongTien FROM INSERTED

	IF @TongTien != (SELECT SUM(ThanhTien) FROM CT_HoaDon WHERE MaHD = @MaHD)
	BEGIN
		RAISERROR('TongTien khong bang tong ThanhToan', 15, 1)
		ROLLBACK
	END
---
GO
CREATE TRIGGER tg_CTHoaDon_insert ON CT_HoaDon AFTER INSERT
AS
	EXEC sp_updateCT_HoaDon --UPDATE CT_HoaDon(GiaBan, GiaGiam)
	UPDATE HoaDon
	SET TongTien = TongTien + 
			(SELECT ThanhTien FROM INSERTED WHERE MaHD = HoaDon.MaHD)
	FROM HoaDon JOIN INSERTED ON HoaDon.MaHD = INSERTED.MaHD
---
GO
CREATE TRIGGER tg_CTHoaDon_delete ON CT_HoaDon FOR DELETE
AS
	UPDATE HoaDon
	SET TongTien = TongTien - 
		(SELECT ThanhTien FROM DELETED WHERE MaHD = HoaDon.MaHD)
	FROM HoaDon JOIN DELETED ON HoaDon.MaHD = DELETED.MaHD
---
GO
CREATE TRIGGER tg_CTHoaDon_update ON CT_HoaDon AFTER UPDATE
AS
	IF UPDATE(MaSP)
		EXEC sp_updateCT_HoaDon --UPDATE SanPham tương ứng
	UPDATE HoaDon
	SET TongTien = TongTien + 
		(SELECT ThanhTien FROM INSERTED WHERE MaHD = HoaDon.MaHD) -
		(SELECT ThanhTien FROM DELETED WHERE MaHD = HoaDon.MaHD)
	FROM HoaDon JOIN DELETED ON HoaDon.MaHD = DELETED.MaHD
---
GO
sp_settriggerorder @triggername = 'tg_CapNhatThanhTien', @order = 'last', @stmttype = 'INSERT'
GO
sp_settriggerorder @triggername = 'tg_CapNhatThanhTien', @order = 'last', @stmttype = 'UPDATE'

--NHẬP DỮ LIỆU
GO
SET DATEFORMAT YMD
SET IDENTITY_INSERT dbo.KhachHang ON
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (1, N'Trương', N'Huy Đức', '1974-05-26 00:00:00.000', '843F', N'Hòa Mỹ', N'Phường 11', N'Quận 5', N'Kon Tum', '0569277696')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (2, N'Đỗ Phạm', N'Thị Kiều Trang', '1951-01-05 00:00:00.000', '90G', N'Nguyễn Văn Đượm', N'Phường 8', N'Quận 1', N'Thành phố Hồ Chí Minh', '0706303943')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (3, N'Nguyễn', N'Hồng Trung', '1998-11-12 00:00:00.000', '582G/93', N'Đỗ Quang Đẩu', N'Phường 9', N'Quận 5', N'Thành phố Hồ Chí Minh', '0701645493')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (4, N'Hoàng ', N'Trà My', '1953-03-30 00:00:00.000', '7Q/60', N'Thái Văn Lung', N'Phường 8', N'Quận 11', N'Thành phố Hồ Chí Minh', '0729271989')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (5, N'Võ ', N'Quyết Thắng', '1951-01-05 00:00:00.000', '289D', N'Sương Nguyệt Ánh', N'Phường 8', N'Quận 1', N'Thành phố Hồ Chí Minh', '0926614323')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (6, N'Ngô ', N'Tiến Phát', '1971-08-26 00:00:00.000', '365O', N'Đinh Công Tránh', N'Phường 3', N'Quận 1', N'Đồng Nai', '0131997710')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (7, N'Lê ', N'Thùy Yến Nhi', '1961-01-10 00:00:00.000', '9N', N'Cô Bắc', N'Phương 4', N'Quận 10', N'Thành phố Hồ Chí Minh', '0630916203')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (8, N'Phạm', N'Thị Thùy Trang', '1960-05-28 00:00:00.000', '63H', N'Phan Liêm', N'Phường 5', N'Quận 12', N'Thành phố Hồ Chí Minh', '0797157312')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (9, N'Phan ', N'Nguyệt Phương', '1994-12-25 00:00:00.000', '315O', N'Thạch Thị Thanh', N'Phường 2', N'Quận 3', N'Thành phố Hồ Chí Minh', '0135870664')
INSERT dbo.KhachHang(MaKH, Ho, Ten, Ngsinh, SoNha, Duong, Phuong, Quan, Tpho, DienThoai) VALUES (10, N'Đỗ ', N'Thị Thanh Thủy', '1971-01-23 00:00:00.000', '837O', N'Trần Cao Vân', N'Phường 11', N'Quận 3', N'Thành phố Hồ Chí Minh', '0705569757')

SET IDENTITY_INSERT dbo.KhachHang OFF

--SELECT * FROM KhachHang

SET IDENTITY_INSERT dbo.SanPham ON
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (1, N'Loa di động bluetooth LG P7 2018 Chính hãng', 442, NULL, 779200)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (2, N'Loa di động bluetooth JBL Go 2 [Nobox] 2018 Chính hãng', 54, NULL, 597000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (3, N'Loa di động móc khóa JBL Clip 3 [Nobox]	 2018', 389, NULL, 213000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (4, N'Loa Bluetooth Sony Extra Bass SRS-XB32', 249, NULL, 343000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (5, N'Loa bluetooth Sony Extra Bass SRS-XB22 2021', 102, N'Loa có công suất 3W, kết nối bluetooth 4.1.', 303500)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (6, N'Loa di động bluetooth JBL Go 2 [Nobox]', 382, NULL, 278500)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (7, N'Loa Soundbar TV Bose Solo 5 chính hãng [Likenew]', 313, NULL, 192000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (8, N'Loa Bluetooth Klipsch Heritage Groove 2020 Chính hãng', 339, N'Loa không dây JBL Go 2 – Nhỏ gọn, âm thanh sống động.', 503700)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (9, N'Loa di động Sony SRS-XB43 Extrabass', 291, N'Extrabass. Chống nước, chống bụi chuẩn IP67.', 444200)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (10, N'Loa Sony SRS-XB33 EXTRA BASS  2018 Chính hãng', 51, NULL, 407000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (11, N'LOA BLUETOOTH SONY SRS- XB01 2020 Chính hãng', 50, NULL, 473800)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (12, N'Loa di động bluetooth JBL Go 2 [Nobox] Chính hãng', 476, NULL, 235000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (13, N'Loa sony SRS-XB23 extra bass  Chính hãng', 217, NULL, 863300)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (14, N'Loa Sony SRS-XB33 EXTRA BASS  2021', 199, NULL, 585700)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (15, N'Loa Bluetooth Aomais Life Chính hãng', 345, NULL, 758300)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (16, N'Loa di động Bluetooth LG XBOOM Go PL7  2020', 266, N'Extrabass. ', 799400)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (17, N'Loa di động móc khóa JBL Clip 3 [Nobox]	 2018', 349, N'Pin Li-ion cao cấp 750mAh cho thời gian sử dụng 5 tiếng.', 189300)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (18, N'Loa bluetooth Sony Extra Bass SRS-XB22 2021', 312, N'àm cho âm thanh TV trở nên hấp dẫn hơn.', 161000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (19, N'Loa Bluetooth Aomais Life  Chính hãng', 264, NULL, 630300)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (20, N'LOA BLUETOOTH SONY SRS-XB41  Chính hãng', 225, N'Phụ kiện đi kèm có dây sạc , tặng thêm nút dự phòng. ', 888000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (21, N'Loa bluetooth Sony Extra Bass SRS-XB22 2019 Chính hãng', 429, NULL, 645700)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (22, N'Loa sony SRS-XB23 extra bass  2019 Chính hãng', 417, NULL, 635100)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (23, N'Loa Bluetooth di động LG XBOOM Go PL2 	 Chính hãng', 153, NULL, 406700)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (24, N'Loa di động móc khóa JBL Clip 3 [Nobox]	', 364, NULL, 902400)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (25, N'Loa di động móc khóa JBL Clip 3 [Nobox]	 2021', 373, N'G XBOOM Go PL5-Khuấy đảo cuộc vui bất tận.', 625000)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (26, N'Loa Bluetooth Klipsch Heritage Groove 2019 Chính hãng', 104, NULL, 473500)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (27, N'Loa sony SRS-XB23 extra bass ', 73, NULL, 471500)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (28, N'Loa Bluetooth Sony Extra Bass SRS-XB32 Chính hãng', 343, NULL, 262100)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (29, N'Loa di động móc khóa JBL Clip 3 [Nobox]	', 171, NULL, 838900)
INSERT dbo.SanPham(MaSP, TenSP, SoLuongTon, Mota, Gia) VALUES (30, N'LOA BLUETOOTH SONY SRS- XB01 2020', 430, N'àm cho âm thanh TV trở nên hấp dẫn hơn.', 760400)

SET IDENTITY_INSERT dbo.SanPham OFF
--SELECT * FROM SanPham

--autofill MaHD
SET IDENTITY_INSERT dbo.HoaDon ON
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (1, 1, '2020-06-05 21:37:31.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (2, 2, '2020-05-01 00:00:07.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (3, 2, '2020-05-01 00:00:09.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (4, 7, '2020-05-01 00:31:40.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (5, 1, '2020-05-01 00:00:01.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (6, 8, '2020-07-15 15:59:32.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (7, 6, '2020-05-11 22:49:55.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (8, 3, '2021-01-23 06:35:39.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (9, 2, '2020-11-24 14:32:58.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (10, 1, '2020-08-10 17:00:47.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (11, 5, '2021-03-03 02:38:10.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (12, 8, '2020-10-06 20:32:09.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (13, 7, '2020-12-11 18:07:29.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (14, 6, '2020-12-11 09:18:20.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (15, 6, '2021-02-11 13:32:23.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (16, 8, '2020-05-01 00:12:43.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (17, 7, '2021-02-28 20:09:51.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (18, 7, '2020-05-01 00:00:03.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (19, 6, '2020-05-31 22:04:53.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (20, 1, '2020-10-12 02:25:24.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (21, 4, '2021-06-15 07:13:49.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (22, 2, '2020-05-01 00:00:05.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (23, 2, '2020-05-01 00:00:02.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (24, 4, '2021-06-28 16:08:40.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (25, 9, '2021-01-30 00:08:40.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (26, 5, '2021-01-30 05:33:23.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (27, 6, '2020-05-01 00:14:48.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (28, 2, '2020-05-01 00:00:02.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (29, 8, '2020-05-01 00:09:08.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (30, 7, '2020-07-25 06:05:14.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (31, 9, '2021-03-03 17:07:57.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (32, 6, '2020-12-05 16:22:30.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (33, 9, '2020-05-01 00:08:45.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (34, 1, '2020-11-26 02:55:52.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (35, 6, '2020-05-01 00:00:54.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (36, 9, '2020-05-01 00:14:52.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (37, 7, '2020-11-25 13:55:04.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (38, 3, '2020-05-01 00:00:07.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (39, 3, '2020-11-16 01:05:56.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (40, 9, '2020-05-01 00:01:38.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (41, 6, '2021-03-14 08:30:30.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (42, 9, '2020-06-26 04:44:50.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (43, 1, '2020-05-01 00:08:52.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (44, 7, '2021-05-25 08:40:48.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (45, 1, '2021-01-09 22:01:00.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (46, 7, '2021-01-29 01:27:50.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (47, 4, '2020-05-01 00:05:05.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (48, 9, '2021-04-01 09:26:49.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (49, 7, '2020-10-06 01:14:41.000')
INSERT dbo.HoaDon(MaHD, MaKH, NgayLap) VALUES (50, 5, '2021-06-08 14:59:59.000')

SET IDENTITY_INSERT HoaDon OFF
--SELECT * FROM HoaDon

INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (1, 2, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (1, 1, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (2, 3, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (1, 4, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (2, 1, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (2, 5, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (3, 3, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (3, 7, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (4, 9, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (4, 8, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (4, 29, 4)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (5, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (6, 15, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (6, 11, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (7, 19, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (8, 18, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (9, 8, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (10, 16, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (10, 22, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (11, 23, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (12, 2, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (12, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (14, 1, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (15, 11, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (16, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (18, 18, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (17, 8, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (18, 6, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (19, 27, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (19, 28, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (20, 21, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (19, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (20, 14, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (21, 11, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (21, 19, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (21, 18, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (22, 8, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (22, 6, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (23, 7, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (24, 28, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (24, 21, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (24, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (25, 4, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (25, 11, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (26, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (24, 18, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (27, 8, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (27, 1, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (28, 7, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (29, 8, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (30, 1, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (31, 19, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (30, 24, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (31, 21, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (32, 19, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (32, 8, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (33, 18, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (33, 12, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (33, 27, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (34, 11, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (34, 18, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (35, 29, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (36, 14, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (37, 17, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (37, 21, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (38, 19, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (39, 28, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (39, 14, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (39, 1, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (38, 9, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (40, 6, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (40, 1, 3)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (40, 14, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (40, 16, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (41, 12, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (42, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (42, 18, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (43, 7, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (43, 22, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (43, 28, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (44, 1, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (44, 8, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (45, 9, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (46, 4, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (47, 12, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (47, 27, 1)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (48, 29, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (49, 18, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (49, 24, 2)
INSERT dbo.CT_HoaDon(MaHD, MaSP, SoLuong) VALUES (50, 19, 1)
--SELECT * FROM CT_HoaDon