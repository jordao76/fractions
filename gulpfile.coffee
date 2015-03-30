gulp = require 'gulp'
$ = (require 'gulp-load-plugins')()

gulp.task 'peg', ->
  gulp.src 'app/scripts/fractions-peg-parser.pegjs'
    .pipe $.peg().on "error", console.error
    .pipe gulp.dest 'app/scripts'

gulp.task 'lint', ->
  gulp.src ['app/scripts/**/*.js', '!app/scripts/fractions-peg-parser.js']
    .pipe $.eslint
      rules:
        'quotes': 0
        'space-infix-ops': 0
        'comma-spacing': 0
        'key-spacing': 0
        'no-return-assign': 0
        'curly': 0
        'new-cap': 0
      envs: ['browser']
    .pipe $.eslint.format()
    .pipe $.eslint.failOnError()

gulp.task 'test', ['peg'], ->
  gulp.src 'app/specs/**.js'
    .pipe $.jasmine()

gulp.task 'scripts', ['peg'], ->
  browserify = require 'browserify'
  source = require 'vinyl-source-stream'
  buffer = require 'vinyl-buffer'

  browserify {entries: ['./app/scripts/index.js'], baseDir: './app/scripts'}
    .bundle()
    .pipe source 'main.min.js'
    .pipe buffer()
    .pipe $.sourcemaps.init {loadMaps: true}
    .pipe $.uglify()
    .pipe $.sourcemaps.write './'
    .pipe gulp.dest 'dist/scripts'

gulp.task 'images', ->
  gulp.src ['app/images/*.*']
    .pipe gulp.dest 'dist/images'

gulp.task 'html', ->
  assets = $.useref.assets {searchPath: 'app'}
  gulp.src 'app/*.html'
    .pipe assets
    .pipe $.if '*.css', $.csso()
    .pipe assets.restore()
    .pipe $.useref()
    .pipe $.if '*.html', $.minifyHtml {conditionals: true}
    .pipe gulp.dest 'dist'

gulp.task 'extras', ->
  gulp.src ['app/*.*', '!app/*.html']
    .pipe gulp.dest 'dist'

gulp.task 'build', ['lint', 'test', 'scripts', 'images', 'html', 'extras'], ->
  gulp.src 'dist/**/*'
    .pipe $.size {title: 'build', gzip: true}

gulp.task 'clean', 
  require 'del'
    .bind null, ['dist', 'app/scripts/fractions-peg-parser.js']

gulp.task 'default', ['clean'], ->
  gulp.start 'build'

# serve

gulp.task 'connect', ->
  serveStatic = require 'serve-static'
  app = (require 'connect')()
    .use (require 'connect-livereload') {port: 35729}
    .use serveStatic 'dist'
    # paths to bower_components should be relative to the current file
    # e.g. in app/index.html use ../bower_components
    .use '/bower_components', serveStatic 'bower_components'

  require 'http'
    .createServer app
    .listen 9000
    .on 'listening', -> console.log 'Started connect web server on http://localhost:9000'

gulp.task 'watch', ['connect'], ->
  gulp.watch ['app/scripts/**/*.js', 'app/scripts/**/*.pegjs'], ['scripts']
  gulp.watch ['app/*.html', 'app/styles/**/*.css'], ['html']

  $.livereload.listen()
  gulp.watch ['dist/*.html', 'dist/styles/**/*.css', 'dist/scripts/**/*.js']
    .on 'change', $.livereload.changed

gulp.task 'serve', ['watch'], ->
  (require 'opn') 'http://localhost:9000'
