function show_date_as_local_time() {
    var spans = document.getElementsByTagName('span');
    for (var i=0; i<spans.length; i++)
        if (spans[i].className.match(/\bLOCAL_TIME\b/i)) {
            system_date = new Date(Date.parse(spans[i].innerHTML));
            if (system_date.getHours() >= 12) { adds = '&nbsp;PM'; h = system_date.getHours() - 12; } 
            else { adds = '&nbsp;AM'; h = system_date.getHours(); }
            spans[i].innerHTML = h + ":" + (system_date.getMinutes()+"").replace(/\b(\d)\b/g, '0$1') + adds;    
        }
}
