$(function(){
    $('.advanced-install.link').click(function(){
        $('#advanced-install').toggle();
    });

    $('.advanced-install-form').submit(function(e){
        e.preventDefault();
        var install = 'bash vst-install.sh';

        $('.advanced-install-form .val').each(function(i, elm){
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

        $('.code-incut.advanced').fadeOut(100).fadeIn(100);
        $('.code-incut.advanced .install-line').text(install);
    });
});