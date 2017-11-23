$(function(){
    var animationTime = 100;

    $('.advanced-install.link').click(function(){
        $('#advanced-install').toggle();
    });

    $('#fpm').change(function (e) {
        if(this.val() == '--nginx yes --phpfpm yes --apache no'){
            $('#fpm').fadeOut(animationTime);
        } else {
            $('#fpm').fadeIn(animationTime);
        }
    });

    $('#install-form').submit(function(e){
        e.preventDefault();
        var install = 'bash vst-install.sh';

        $('#install-form .form-control').each(function(i, elm){
            if(elm.type == 'checkbox'){
                if(elm.checked){
                    install += ' '+$(elm).attr('option-name')+' yes'
                } else {
                    install += ' '+$(elm).attr('option-name')+' no'
                }
            } else if(elm.type == 'text'){
                if(elm.value){
                    install += ' '+elm.name+' '+elm.value;
                }
            } else if(elm.value) {
                install += ' '+elm.value;
            }
        });

        $('#code').fadeOut(animationTime).fadeIn(animationTime);
        $('#code #install-line').text(install);
    });
});