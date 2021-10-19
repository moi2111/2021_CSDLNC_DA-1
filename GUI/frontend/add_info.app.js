$('#btnSave').on('click', function () {
    var objToPost = {
        // id: $('#txtId').val(),
        MaHD: $('#txtMaHD').val(),
        MaSP: $('#txtMaSP').val(),
        SoLuong: $('#txtSoLuong').val(),
        GiaBan: $('#txtGiaBan').val(),
        GiaGiam: $('#txtGiaGiam').val(),
        ThanhTien: $('#txtThanhTien').val(),
    }

    $.ajax({
        url: 'http://localhost:3000/ct_hoadon',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(objToPost),
        dataType: 'json',
        timeout: 10000,
    }).done(function (data) {
        if(data.error) {
            $('#invoiceAddErrorModal').modal('show');
        } else {
            $('#invoiceAddModal').modal('show');
        }
    }).fail(function (xhr, textStatus, error) {
        console.log(textStatus);
        console.log(error);
        console.log(xhr)
    });
})