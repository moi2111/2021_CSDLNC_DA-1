$(function () {
    var url = 'http://localhost:3000/students';
    $.ajax(url)
        .done(function (data) {
            var source = document.getElementById('entry-template').innerHTML;
            var template = Handlebars.compile(source);
            var html = template(data);
            $('#invoices-list').html(html);
        }).fail(function (err) {
            console.log(err);
        })
})

$('#invoices-list').on('click', '.delinvoice', function () {
    var button = $(this);
    var id = button.data('id');
    $.ajax({
        url: 'http://localhost:3000/students/' + id,
        type: 'DELETE',
        dataType: 'json',
        timeout: 10000,
    }).done(function (data) {
        // console.log(data);
        button.closest('tr').remove();
    }).fail(function (xhr, textStatus, error) {
        console.log(textStatus);
        console.log(error); 
        console.log(xhr);
    });
})

var focusedRow;

$('#invoiceModal').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var id = button.data('id') 
    focusedRow = button.closest('tr');
    console.log(focusedRow);

    var modal = $(this);
    var url = 'http://localhost:3000/students/' + id;
    $.ajax(url)
        .done(function (data) {
            modal.find('#txtId').val(id);
            modal.find('#txtMaHD').val(data.MaHD);
            modal.find('#txtMaKH').val(data.MaKH);
            modal.find('#txtDay').val(data.NgayLap);
            modal.find('#txtTotal').val(data.TongTien);
        }).fail(function (err) {
            console.log(err);
        })
})

$('#btnSave').on('click', function () {
    var id = $('#txtId').val();
    var objToPatch = {
        MaHD: $('#txtMaHD').val(),
        MaKH: $('#txtMaKH').val(),
        NgayLap: $('#txtDay').val(),
        TongTien: $('#txtTotal').val(),
    }

    $.ajax({
        url: 'http://localhost:3000/students/' + id,
        type: 'PATCH',
        contentType: 'application/json',
        data: JSON.stringify(objToPatch),
        dataType: 'json',
        timeout: 10000,
    }).done(function (data) {
        if(focusedRow) {
            focusedRow.find('td').each(function (idx, td) {
                switch(idx) {
                    case 0: // MaHD
                        $(td).html(data.MaHD);
                        break;

                    case 1: // MaKH
                        $(td).html(data.MaKH);
                        break;

                    case 2: // Ngày Lập
                        $(td).html(data.NgayLap);
                        break;

                    case 3: // Tổng tiền
                        $(td).html(data.TongTien);
                        break;

                    default:
                        break;
                } 
            });
        }
        $('#invoiceModal').modal('hide');
    }).fail(function (xhr, textStatus, error) {
        console.log(textStatus);
        console.log(error);
        console.log(xhr);
    });
})