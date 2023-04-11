#!chezscheme
(library (letloop lsm)

  (export
   lsm-begin
   lsm-close
   lsm-commit
   lsm-config
   lsm-cursor-close
   lsm-cursor-first
   lsm-cursor-key
   lsm-cursor-last
   lsm-cursor-next
   lsm-cursor-open
   lsm-cursor-prev
   lsm-cursor-seek
   lsm-cursor-valid?
   lsm-cursor-value
   lsm-delete
   lsm-insert
   lsm-new
   lsm-open
   lsm-rollback
   )

  (import (chezscheme))

  (define-syntax define-syntax-rule
    (syntax-rules ()
      ((define-syntax-rule (keyword args ...) body)
       (define-syntax keyword
         (syntax-rules ()
           ((keyword args ...) body))))))

  (define (bytevector->pointer bv)
    (#%$object-address bv (+ (foreign-sizeof 'void*) 1)))

  ;; TODO: take a list of objects.
  (define (call-with-lock obj thunk)
    (lock-object obj)
    (call-with-values thunk
      (lambda out
        (unlock-object obj)
        (apply values out))))

    ;; ffi helpers

    (define (make-double-pointer)
      (foreign-alloc 8))

    (define-syntax-rule (dereference  pointer)
      (foreign-ref 'void* pointer 0))

    (define-syntax-rule (ftype->pointer ftype)
      (ftype-pointer-address ftype))

    (define-syntax-rule (foreign-procedure* return ptr args ...)
      (foreign-procedure ptr (args ...) return))

    ;; sqlite lsm extension bindings

    (define okvslite (load-shared-object "lsm.so"))

    (define (error->message code)
      (case code
        ((1) "ERROR")
        ((5) "BUSY")
        ((7) "NO MEMORY")
        ((8) "READ ONLY")
        ((10) "IO ERROR")
        ((11) "CORRUPT")
        ((13) "FULL")
        ((14) "CAN NOT OPEN")
        ((15) "PROTOCOL")
        ((21) "MISUSE")
        ((50) "MISMATCH")
        (else "UNKNOWN ERROR")))

    (define-syntax-rule (check sym code)
      (let ((code* code))
        (unless (zero? code*)
          (error 'okvslite (error->message code*) code* sym))))

    (define lsm-new
      (let ((proc (foreign-procedure* int "lsm_new" void* void*)))
        (lambda ()
          (let ((out (make-double-pointer)))
            (check 'lsm-new (proc 0 out))
            (dereference out)))))

    (define lsm-close
      (let ((proc (foreign-procedure* int "lsm_close" void*)))
        (lambda (db)
          (check 'lsm-close (proc db)))))

    ;; TODO: replace with symbols
    (define lsm-config
      (let ((proc (foreign-procedure* int "lsm_config" void* int void*)))
        (lambda (db config value)
          (let ((pointer (make-double-pointer)))
            (foreign-set! 'int pointer 0 value)
            (check 'lsm-config (proc db config pointer))))))

    (define lsm-open
      (let ((proc (foreign-procedure "lsm_open" (void* string) int)))
        (lambda (db filename)
          (check 'lsm-open (proc db filename)))))

    (define lsm-begin
      (let ((proc (foreign-procedure* int "lsm_begin" void* int)))
        (lambda (db level)
          (check 'lsm-begin (proc db level)))))

    (define lsm-commit
      (let ((proc (foreign-procedure* int "lsm_commit" void* int)))
        (lambda (db level)
          (check 'lsm-commit (proc db level)))))

    (define lsm-rollback
      (let ((proc (foreign-procedure* int "lsm_rollback" void* int)))
        (lambda (db level)
          (check 'lsm-rollback (proc db level)))))

    (define lsm-insert
      (let ((proc (foreign-procedure* int "lsm_insert" void* void* int void* int)))
        (lambda (db key value)
          (call-with-lock key
            (lambda ()
              (call-with-lock value
                (lambda ()
                  (check 'lsm-insert
                         (proc db
                               (bytevector->pointer key)
                               (bytevector-length key)
                               (bytevector->pointer value)
                               (bytevector-length value))))))))))

    (define lsm-delete
      (let ((proc (foreign-procedure* int "lsm_delete" void* void* int)))
        (lambda (db key)
          (call-with-lock key
            (lambda ()
              (check 'lsm-delete
                     (proc db
                           (bytevector->pointer key)
                           (bytevector-length key))))))))

    (define lsm-cursor-open
      (let ((proc (foreign-procedure* int "lsm_csr_open" void* void*)))
        (lambda (db)
          (let ((out (make-double-pointer)))
            (check 'lsm-cursor-open
                   (proc db out))
            (dereference out)))))

    (define lsm-cursor-close
      (let ((proc (foreign-procedure* int "lsm_csr_close" void*)))
        (lambda (cursor)
          (check 'lsm-cursor-close (proc cursor)))))

    (define (->seek symbol)
      (case symbol
        ((less-than-or-equal-fast) -2)
        ((less-than-or-equal) -1)
        ((equal) 0)
        ((greater-than-or-equal) 1)
        (else (error 'okvslite "unknown seek strategy"))))

    (define lsm-cursor-seek
      (let ((proc (foreign-procedure* int "lsm_csr_seek" void* void* int int)))
        (lambda (cursor key strategy)
          (call-with-lock key
            (lambda ()
              (check 'lsm-cursor-seek
                     (proc cursor
                           (bytevector->pointer key)
                           (bytevector-length key)
                           (->seek strategy))))))))

    (define lsm-cursor-first
      (let ((proc (foreign-procedure* int "lsm_csr_first" void*)))
        (lambda (cursor)
          (check 'lsm-cursor-first (proc cursor)))))

    (define lsm-cursor-last
      (let ((proc (foreign-procedure* int "lsm_csr_last" void*)))
        (lambda (cursor)
          (check 'lsm-cursor-last (proc cursor)))))

    (define lsm-cursor-next
      (let ((proc (foreign-procedure* int "lsm_csr_next" void*)))
        (lambda (cursor)
          (check 'lsm-cursor-next (proc cursor)))))

    (define lsm-cursor-prev
      (let ((proc (foreign-procedure* int "lsm_csr_prev" void*)))
        (lambda (cursor)
          (check 'lsm-cursor-prev (proc cursor)))))

    (define lsm-cursor-valid?
      (let ((proc (foreign-procedure* int "lsm_csr_valid" void*)))
        (lambda (cursor)
          (= (proc cursor) 1))))

    (define lsm-cursor-key
      (let ((proc (foreign-procedure* int "lsm_csr_key" void* void* void*)))
        (lambda (cursor)
          (let ((data* (make-double-pointer))
                (length* (make-double-pointer)))
            (check 'lsm-cursor-key (proc cursor data* length*))
            ;; copy the data into a scheme bytevector
            (let* ((data (dereference data*))
                   (length (foreign-ref 'int length* 0))
                   (bytevector (make-bytevector length)))
              (let loop ((index (- length 1)))
                (unless (< index 0)
                  (let ((value (foreign-ref 'unsigned-8 data index)))
                    (bytevector-u8-set! bytevector index value)
                    (loop (- index 1)))))
              bytevector)))))

    (define lsm-cursor-value
      (let ((proc (foreign-procedure* int "lsm_csr_value" void* void* void*)))
        (lambda (cursor)
          (let ((data* (make-double-pointer))
                (length* (make-double-pointer)))
            (check 'lsm-cursor-value (proc cursor data* length*))
            ;; copy the data into a scheme bytevector
            (let* ((data (dereference data*))
                   (length (foreign-ref 'int length* 0))
                   (bytevector (make-bytevector length)))
              (let loop ((index (- length 1)))
                (unless (< index 0)
                  (let ((value (foreign-ref 'unsigned-8 data index)))
                    (bytevector-u8-set! bytevector index value)
                    (loop (- index 1)))))
              bytevector))))))
