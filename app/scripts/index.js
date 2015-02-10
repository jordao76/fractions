/* global MathJax,require,jQuery */
(function(MathJax, $, Processor){
'use strict';

$(function(){

  var $input = $('#input');
  var $output = $('#output');
  var $buffer = $('#buffer');
  var $parsed = $('#parsed');
  var $decimal = $('#decimal');

  var typeset = function(s) {
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

  var output = function(s) {
    typeset(s);
  };

  var last = null;
  var process = function(doCalc) {
    var exp = $input.val();
    if (!exp.trim()) {
      $decimal.text('');
      output('');
      last = '';
      return;
    }
    var ast = Processor.parse(exp);
    if (doCalc) {
      var result = Processor.calc(ast);
      output(Processor.render(ast, result));
      if (!result.error) {
        $decimal.text(result.toFloat());
        $input.val(last = result.toString());
      }
    }
    else if (exp !== last) {
      output(Processor.render(ast));
      $decimal.text('');
      last = exp;
    }
  };

  $input.keyup(function(e){process(e.which===13);}); // 13 is <ENTER>
  $input.focus();

});

}(MathJax, jQuery, require('./fractions-processor')));
