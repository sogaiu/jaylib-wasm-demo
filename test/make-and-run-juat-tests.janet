(-> ["janet"
     "./janet-usages-as-tests/janet-usages-as-tests/make-and-run-tests.janet"
     # specify file and/or directory paths relative to project root
     "./resources/lateral.janet"
     "./resources/turn.janet"
     "./resources/fall.janet"
     ]
    (os/execute :p)
    os/exit)

