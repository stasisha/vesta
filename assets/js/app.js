$(function () {
    var animationTime = 100;

    $('.advanced-install.link').click(function () {
        $('#advanced-install').toggle();
    });

    $('#web').change(function (e) {
        if (this.val() == '--nginx yes --phpfpm yes --apache no') {
            $('#fpm').fadeOut(animationTime);
            $('#fpm input').each(function (index) {
                $(this).val('--phpfpm' + $(this).data('fpm') + ' yes');
            });
        } else {
            $('#fpm').fadeIn(animationTime);
            $('#fpm input').each(function (index) {
                $(this).val('--phpfpm' + $(this).data('fpm') + ' no');
            });
        }
    });

    $('#install-form').submit(function (e) {
        e.preventDefault();
        var install = 'bash vst-install.sh';

        $('#install-form .form-control').each(function (i, elm) {
            if (elm.type == 'text') {
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