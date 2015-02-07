/* jshint devel:true */
(function($, MathJax, Processor){
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
      $buffer.text("`" + s + "`");
      MathJax.Hub.Typeset($buffer.get(), function() {
        if ($parsed.text() === s) {
          $output.html($buffer.html());
        }
      });
    });
  };

  var output = function(s) {
    if (window.MathJax) {
      typeset(s);
    }
    else {
      $parsed.text(s);
      $output.text(s);
    }
  };

  var last = null;
  $input.keyup(function(e){
    var exp = $input.val();
    if (!exp.trim()) {
      $decimal.text('');
      output('');
      last = '';
      return;
    }
    var ast = Processor.parse(exp);
    if (e.which === 13) { // <ENTER>
      var result = Processor.calc(ast);
      output(Processor.render(ast, result));
      if (!result.error) {
        $decimal.text(window.eval(result));
        $input.val(result);
        last = result;
      }
    }
    else if (exp !== last) {
      output(Processor.render(ast));
      $decimal.text('');
      last = exp;
    }
  });

});

}(jQuery, MathJax, Processor));
