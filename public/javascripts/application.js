// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
replace_ids = function(s){
    var new_id = new Date().getTime();
    return s.replace(/NEW_RECORD/g, new_id);
}

var myrules = {
    '.remove': function(e){
        el = Event.findElement(e);
        target = el.href.replace(/.*#/, '.')
        el.up(target).hide();
        if(hidden_input = el.previous("input[type=hidden]")) hidden_input.value = '1'
    },
    '.add_nested_item': function(e){
        el = Event.findElement(e);
        template = eval(el.href.replace(/.*#/, ''))
        $(el.rel).insert({
            bottom: replace_ids(template)
        });
    },
    '.add_nested_item_lvl2': function(e){
        el = Event.findElement(e);
        elements = el.rel.match(/(\w+)/g)
        parent = '.'+elements[0]
        child = '.'+elements[1]

        child_container = el.up(parent).down(child)
        parent_object_id = el.up(parent).down('input').name.match(/.*\[(\d+)\]/)[1]

        template = eval(el.href.replace(/.*#/, ''))

        template = template.replace(/(attributes[_\]\[]+)\d+/g, "$1"+parent_object_id)

        // console.log(template)
        child_container.insert({
            bottom: replace_ids(template)
        });
    }
};

Event.observe(window, 'load', function(){
    $('container').delegate('click', myrules);
});


function after_complete_transfer_item(name)
{
    var x = document.getElementById(name + 'description_complete');
    aa = x.getElementsByTagName('li');
    for(var i=0; i < aa.length; i++){
        current_li = aa[i];
        if(current_li.className == 'autocomplete_item selected') {
            elements = current_li.getElementsByTagName('a');
            for(var j=0; j < elements.length; j++){
                el = elements[j];

                if(el.className == 'autocomplete-value') {
                    document.getElementById(name + 'value').value = el.innerHTML;
                }
                if(el.className == 'autocomplete-category') {
                    document.getElementById(name + 'category_id').value = el.innerHTML;
                }
                if(el.className == 'autocomplete-currency') {
                    document.getElementById(name + 'currency_id').value = el.innerHTML;
                }
            }
            break;
        }
    }
}
