
$(function () {
    var url = 'http://localhost:3000/ct_hoadon/';
    $.ajax(url)
        .done(function (data) {
            var source = document.getElementById('entry-template').innerHTML;
            var template = Handlebars.compile(source);
            var html = template(data.result);
            // console.log(data)
            $('#invoices-list').html(html);
        }).fail(function (err) {
            console.log(err);
        })
})
