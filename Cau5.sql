--Cau5
--a. Dung where
SELECT *
FROM HOADON HD, CT_HOADON CTHD, SANPHAM SP
WHERE HD.MAHD=CTHD.MAHD AND CTHD.MASP=SP.MASP
--a. Dung join
SELECT *
FROM HOADON HD
INNER JOIN CT_HOADON CTHD ON HD.MAHD=CTHD.MAHD
JOIN SANPHAM SP ON CTHD.MASP=SP.MASP

--b. A la san pham, B la chi tiet hoa don
SELECT *
FROM SANPHAM SP JOIN CT_HOADON CTHD ON SP.MASP=CTHD.MASP
--b. dao
SELECT *
FROM CT_HOADON CTHD JOIN SANPHAM SP ON CTHD.MASP=SP.MASP