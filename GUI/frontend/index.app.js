$(function() {
    var url = 'http://localhost:3000/hoadon';
    $.ajax(url)
        .done(function (data) {
            var range = [];
            for (var i = 1; i <= data.pageCount; i++) {
                range.push(i);
            }
            var source = document.getElementById('pagination-template').innerHTML;
            var template = Handlebars.compile(source);
            var html = template(range);
            $('#pagination-container').html(html);
        }).fail(function (err) {
            console.log(err);
        })
})

$(function () {
    var page = 1; //
    var url = 'http://localhost:3000/hoadon/page/' + page;
    renderPage(url);
})

function renderPage(url) {
    $.ajax(url)
        .done(function (data) {
            var source = document.getElementById('entry-template').innerHTML;
            var template = Handlebars.compile(source);
            var html = template(data.result);
            $('#invoices-list').html(html);
        }).fail(function (err) {
            console.log(err);
        })
}

// Khi click vào từng pagination
$('#pagination-container').on('click', '.page-item', function () {
    var button = $(this);
    if ($('.page-item').hasClass('active')) {
        $('.page-item').removeClass('active')
    }
    button.addClass('active');
    page = button.children().data('id');
    var url = 'http://localhost:3000/hoadon/page/' + page;
    renderPage(url);
})

$('#invoices-list').on('click', '.delinvoice', function () {
    var button = $(this);
    var id = button.data('id');
    $.ajax({
        url: 'http://localhost:3000/hoadon/' + id,
        type: 'DELETE',
        dataType: 'json',
        timeout: 10000,
    }).done(function (data) {
        // console.log(data)
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
    var url = 'http://localhost:3000/hoadon/' + id;
    $.ajax(url)
        .done(function (data) {
            // modal.find('#txtId').val(id);
            // modal.find('#txtMaHD').val(data.MaHD);
            modal.find('#txtMaHD').val(id);
            modal.find('#txtMaKH').val(data.result.MaKH);
            modal.find('#txtDay').val(data.result.NgayLap);
            modal.find('#txtTotal').val(data.result.TongTien);
        }).fail(function (err) {
            console.log(err);
        })
})

$('#btnSave').on('click', function () {
    // var id = $('#txtId').val();
    var id = $('#txtMaHD').val()
    var objToPatch = {
        MaKH: $('#txtMaKH').val(),
        NgayLap: $('#txtDay').val(),
        TongTien: $('#txtTotal').val(),
    }

    $.ajax({
        url: 'http://localhost:3000/hoadon/' + id,
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