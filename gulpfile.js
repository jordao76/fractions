'use strict';
var gulp = require('gulp');
var $ = require('gulp-load-plugins')();

gulp.task('jshint', function () {
  return gulp.src('app/scripts/**/*.js')
    .pipe($.jshint())
    .pipe($.jshint.reporter('jshint-stylish'))
    .pipe($.jshint.reporter('fail'));
});

gulp.task('peg', function () {
  return gulp.src('app/scripts/*.peg')
    .pipe($.peg({exportVar: 'var Parser'}).on("error", console.error))
    .pipe(gulp.dest('dist/scripts'));
});

gulp.task('html', ['peg'], function () {
  var assets = $.useref.assets({searchPath: 'app'});
  return gulp.src('app/*.html')
    .pipe(assets)
    .pipe($.if('*.js', $.uglify()))
    .pipe($.if('*.css', $.csso()))
    .pipe(assets.restore())
    .pipe($.useref())
    .pipe($.if('*.html', $.minifyHtml({conditionals: true})))
    .pipe(gulp.dest('dist'));
});

gulp.task('extras', function () {
  return gulp.src([
    'app/*.*',
    '!app/*.html'
  ]).pipe(gulp.dest('dist'));
});

gulp.task('clean', require('del').bind(null, 'dist'));

gulp.task('build', [/*'jshint',*/ 'html', 'extras'], function () {
  return gulp.src('dist/**/*').pipe($.size({title: 'build', gzip: true})); // TODO: MathJax!
});

gulp.task('default', ['clean'], function () {
  gulp.start('build');
});

gulp.task('connect', function () {
  var serveStatic = require('serve-static');
  var app = require('connect')()
    .use(require('connect-livereload')({port: 35729}))
    .use(serveStatic('dist'))
    // paths to bower_components should be relative to the current file
    // e.g. in app/index.html use ../bower_components
    .use('/bower_components', serveStatic('bower_components'));

  require('http').createServer(app)
    .listen(9000)
    .on('listening', function () {
      console.log('Started connect web server on http://localhost:9000');
    });
});

gulp.task('watch', ['connect'], function () {
  $.livereload.listen();

  // watch for changes
  gulp.watch([
    'app/*.html',
    'app/styles/**/*.css',
    'app/scripts/**/*.js'
  ]).on('change', $.livereload.changed);

});

gulp.task('serve', ['watch'], function () {
  require('opn')('http://localhost:9000');
});
