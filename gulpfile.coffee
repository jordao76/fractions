# coffeelint: disable=max_line_length

gulp = require 'gulp'
$ = (require 'gulp-load-plugins')()

gulp.task 'peg', ->
  gulp.src 'app/scripts/fractions-peg-parser.peg'
    .pipe $.peg().on 'error', console.error
    .pipe gulp.dest 'app/scripts'

gulp.task 'lint', ->
  gulp.src ['./gulpfile.coffee', 'app/scripts/**/*.coffee']
    .pipe $.coffeelint()
    .pipe $.coffeelint.reporter()

# TODO: the test task ends the gulp build! so it cannot run before other tasks!
gulp.task 'test', ['peg'], ->
  gulp.src 'app/specs/**.coffee'
    .pipe $.jasmine verbose: false

gulp.task 'scripts', ['peg'], ->
  browserify = require 'browserify'
  source = require 'vinyl-source-stream'
  buffer = require 'vinyl-buffer'
  coffeeify = require 'coffeeify'

  browserify entries: ['./app/scripts/index.coffee'], extensions: ['.coffee'], debug: true
    .transform(coffeeify)
    .bundle()
    .pipe source 'main.min.js'
    .pipe buffer()
    .pipe $.sourcemaps.init loadMaps: true
    .pipe $.uglify()
    .pipe $.sourcemaps.write './'
    .pipe gulp.dest 'dist/scripts'

gulp.task 'images', ->
  gulp.src 'app/images/*.*'
    .pipe gulp.dest 'dist/images'

gulp.task 'html', ->
  assets = $.useref.assets searchPath: 'app'
  gulp.src 'app/*.html'
    .pipe assets
    .pipe $.if '*.css', $.csso()
    .pipe assets.restore()
    .pipe $.useref()
    .pipe $.if '*.html', $.minifyHtml conditionals: true
    .pipe gulp.dest 'dist'

gulp.task 'extras', ->
  gulp.src ['app/*.*', '!app/*.html']
    .pipe gulp.dest 'dist'

gulp.task 'build', ['lint', 'scripts', 'images', 'html', 'extras'], ->
  gulp.src 'dist/**/*'
    .pipe $.size title: 'build', gzip: true

gulp.task 'clean',
  require 'del'
    .bind null, ['dist', 'app/scripts/*.js']

gulp.task 'default', ['clean'], ->
  gulp.start 'build'

# serve

gulp.task 'connect', ->
  connect = require 'connect'
  serveStatic = require 'serve-static'
  app = connect()
    .use (require 'connect-livereload') port: 35729
    .use serveStatic 'dist'
    .use '/bower_components', serveStatic './bower_components'

  require 'http'
    .createServer app
    .listen 9000
    .on 'listening', -> console.log 'Started connect web server on http://localhost:9000'

gulp.task 'watch', ['connect'], ->
  gulp.watch ['app/scripts/**/*.coffee', 'app/scripts/**/*.js', 'app/scripts/**/*.peg'], ['scripts']
  gulp.watch ['app/*.html', 'app/styles/**/*.css'], ['html']

  $.livereload.listen()
  gulp.watch ['dist/*.html', 'dist/styles/**/*.css', 'dist/scripts/**/*.coffee', 'dist/scripts/**/*.js']
    .on 'change', $.livereload.changed

gulp.task 'serve', ['watch'], ->
  (require 'opn') 'http://localhost:9000'

# deploy

gulp.task 'cdnize', ['build'], ->
  gulp.src 'dist/index.html'
    .pipe $.cdnizer [
      file: '/bower_components/MathJax/MathJax.js?config=AM_HTMLorMML-full'
      package: 'MathJax'
      cdn: 'http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=AM_HTMLorMML-full'
    ,
      file: '/bower_components/jquery/dist/jquery.min.js'
      package: 'jquery'
      cdn: 'http://code.jquery.com/jquery-${ version }.min.js'
    ]
    .pipe gulp.dest './dist'

gulp.task 'deploy', ['cdnize'], ->
  gulp.src 'dist/**/*'
    .pipe $.ghPages()
