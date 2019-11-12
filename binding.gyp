{
  "targets": [
    {
      "target_name": "node_sketch_bridge",
      "sources": [
        "main.m"
      ],
      "conditions": [
        [
          "OS=='mac'",
          {
            "defines": [
              "__MACOSX_CORE__"
            ],
            "link_settings": {
              "libraries": [
                "-framework CoreFoundation",
                "-framework AppKit",
                "-framework CoreGraphics"
              ]
            },
            "ccflags": [],
            "xcode_settings": {
              "GCC_ENABLE_CPP_EXCEPTIONS": "YES"
            }
          }
        ]
      ]
    }
  ]
}
