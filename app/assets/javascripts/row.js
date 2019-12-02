$(function(){
 tr_default("#togodb_database_list_data");
 $("#togodb_database_list_data tr").click(function(){
  tr_default("#togodb_database_list_data");
  tr_click($(this));
 });
});

function tr_default(togodbID){
 var vTR = togodbID + " tr";
 $(vTR).css("background-color","#ffffff");
 $(vTR).mouseover(function(){
  $(this).css("background-color","#fff2dc") .css("cursor","pointer")
 });
 $(vTR).mouseout(function(){
  $(this).css("background-color","#ffffff") .css("cursor","normal")
 });
}

function tr_click(trID){
 trID.css("background-color","#ffbd52");
 trID.mouseover(function(){
  $(this).css("background-color","#fff2dc") .css("cursor","pointer")
 });
 trID.mouseout(function(){
  $(this).css("background-color","#ffbd52") .css("cursor","normal")
 });
}
//html tbody id="togodb_database_list_data"
