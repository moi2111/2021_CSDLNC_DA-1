$('#btnSave').on('click', function () {
    var objToPost = {
        // id: $('#txtId').val(),
        // MaHD: $('#txtMaHD').val(),
        MaKH: $('#txtMaKH').val(),
        NgayLap: $('#txtDay').val(),
        // TongTien: $('#txtTotal').val(),
    }

    $.ajax({
        url: 'http://localhost:3000/hoadon',
        type: 'POST',
        contentType: 'application/json',
        data: JSON.stringify(objToPost),
        dataType: 'json',
        timeout: 10000,
    }).done(function (data) {
        console.log(data);
        // $('#invoiceAddModal').modal('show');
        // alert("Success!");
    }).fail(function (xhr, textStatus, error) {
        console.log(textStatus);
        console.log(error);
        console.log(xhr)
    });
})