(title "テストページ")

(css-code "
body {
  text-align:center;
}
#wrap {
  background:#eee;
  border:1px solid #ccc;
  text-align:left;
  margin:0 auto;
  width:50em;
}
")

(body
 `((p "このページはテストページです。")
   (p (a (@ (href "next/")) "次のページ"))))

(wrap (lambda (body)
        `(div (@ (id "wrap"))
              (div (@ (id "navi"))
                   (a (@ (href ,($/))) "トップページ") " - "
                   (a (@ (href ,($/ "next/"))) "次のページ"))
              (h1 ,(title))
              ,@body)))
