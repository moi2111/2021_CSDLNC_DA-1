$(function () {
    $('.form-search').on('submit', function(e) {
        e.preventDefault();
        var month = $('input[name="month"]').val();
        var url = 'http://localhost:3000/hoadon/thongke/' + month;
        $.ajax(url)
        .done(function (data) {
            var source = document.getElementById('entry-template').innerHTML;
            var template = Handlebars.compile(source);
            var html = template(data.result);
            $('#invoices-list').html(html);
        }).fail(function (err) {
            console.log(err);
        })
    })
})
