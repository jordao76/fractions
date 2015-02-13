/* global MathJax,jQuery,require */
(function(MathJax, $, Processor){
'use strict';

$(function(){

  var
    $input = $('#input'),
    $output = $('#output'),
    $buffer = $('#buffer'),
    $parsed = $('#parsed'),
    $decimal = $('#decimal');

  var output = function(s) {
    MathJax.Hub.Queue(function(){
      $parsed.text(s);
      $buffer.text('`' + s + '`');
      MathJax.Hub.Typeset($buffer.get(), function() {
        if ($parsed.text() === s) {
          $output.html($buffer.html());
        }
      });
    });
  };

  var last = null;

  var butFirstClear = function() {
    $decimal.text('');
    output('');
    last = '';
  };

  var process = function() {
    var exp = $input.val();
    if (!exp.trim()) return butFirstClear();
    var ast = Processor.parse(exp);
    if (exp !== last) {
      output(Processor.render(ast));
      $decimal.text('');
      last = exp;
    }
  };

  var calc = function() {
    var exp = $input.val();
    if (!exp.trim()) return butFirstClear();
    var ast = Processor.parse(exp);
    var result = Processor.calc(ast);
    output(Processor.render(ast, result));
    if (!result.error) {
      $decimal.text(result.toFloat());
      $input.val(last = result.toString());
    }
  };

  $input.keyup(function(e){if(e.which===13)calc();}); // 13 is <ENTER>
  $input.on('input propertychange', process);
  $input.focus();

});

}(MathJax, jQuery, require('./fractions-processor')));
