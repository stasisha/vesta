$(function () {
    var animationTime = 100;

    $('.advanced-install.link').click(function () {
        $('#advanced-install').toggle();
    });

    $('#web').change(function (e) {
        if (this.value == '--nginx yes --phpfpm yes --apache no') {
            $('#fpm').show(animationTime);
            $('#fpm input').each(function (index) {
                this.checked = true;
            });
        } else {
            $('#fpm').hide(animationTime);
            $('#fpm input').each(function (index) {
                this.checked = false;
            });
        }
    });

    $('#install-form').submit(function (e) {
        e.preventDefault();
        var install = 'bash vst-install.sh';

        $('#install-form .form-control').each(function (i, elm) {
            if(elm.type == 'checkbox'){
                if(elm.checked){
                    install += ' '+elm.value+' yes'
                } else {
                    install += ' '+elm.value+' no'
                }
            } else if (elm.type == 'text') {
                if (elm.value) {
                    install += ' ' + elm.name + ' ' + elm.value;
                }
            } else if (elm.value) {
                install += ' ' + elm.value;
            }
        });

        $('#code').fadeOut(animationTime).fadeIn(animationTime);
        $('#code #install-line').text(install);
    });
});