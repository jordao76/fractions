'use strict';
var gulp = require('gulp');
var $ = require('gulp-load-plugins')();

gulp.task('lint', function () {
  return gulp.src(['app/scripts/**/*.js', '!app/scripts/fractions-parser.js'])
    .pipe($.eslint({
      rules: {
        'quotes': 0,
        'space-infix-ops': 0,
        'comma-spacing': 0,
        'key-spacing': 0,
        'no-return-assign': 0,
        'curly': 0,
        'new-cap': 0
      },
      envs: ['browser']
    }))
    .pipe($.eslint.format())
    .pipe($.eslint.failOnError());
});

gulp.task('peg', function() {
  return gulp.src('app/scripts/*.pegjs')
    .pipe($.peg().on("error", console.error))
    .pipe(gulp.dest('app/scripts'));
});

// TODO: copy MathJax! jQuery?

gulp.task('scripts', ['peg'], function() {
  var browserify = require('browserify');
  var source = require('vinyl-source-stream');
  var buffer = require('vinyl-buffer');

  return browserify({entries: ['./app/scripts/index.js'], baseDir: './app/scripts'})
    .bundle()
    .pipe(source('main.min.js'))
    .pipe(buffer())
    .pipe($.sourcemaps.init({loadMaps: true}))
    .pipe($.uglify())
    .pipe($.sourcemaps.write('./'))
    .pipe(gulp.dest('dist/scripts'));
});

gulp.task('html', function() {
  var assets = $.useref.assets({searchPath: 'app'});
  return gulp.src('app/*.html')
    .pipe(assets)
    .pipe($.if('*.css', $.csso()))
    .pipe(assets.restore())
    .pipe($.useref())
    .pipe($.if('*.html', $.minifyHtml({conditionals: true})))
    .pipe(gulp.dest('dist'));
});

gulp.task('extras', function() {
  return gulp.src([
    'app/*.*',
    '!app/*.html'
  ]).pipe(gulp.dest('dist'));
});

gulp.task('clean', require('del').bind(null, 'dist'));

gulp.task('build', [/*'lint',*/ 'scripts', 'html', 'extras'], function() {
  return gulp.src('dist/**/*').pipe($.size({title: 'build', gzip: true})); // TODO: MathJax!
});

gulp.task('default', ['clean'], function() {
  gulp.start('build');
});

gulp.task('connect', function() {
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

gulp.task('watch', ['connect'], function() {
  gulp.watch([
    'app/scripts/**/*.js', 
    'app/scripts/**/*.pegjs'
  ], ['scripts']);
  gulp.watch([
    'app/*.html',
    'app/styles/**/*.css'
  ], ['html']);

  $.livereload.listen();
  gulp.watch([
    'dist/*.html',
    'dist/styles/**/*.css',
    'dist/scripts/**/*.js'
  ]).on('change', $.livereload.changed);
});

gulp.task('serve', ['watch'], function() {
  require('opn')('http://localhost:9000');
});
