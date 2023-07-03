(module wow
  (:import [hello :from hello])
  (:import [h :from http-server]))

(h:foo)
(str)

=> ""
{:x 1235}

(.toString 123 16)

=> TypeError: this.input.charCodeAt is not a function

(seq (js:Uint8Array. [0,1,2,3]))
(.of IteratorSeq (.values [0,1,2,3]))
