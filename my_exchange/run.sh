#!/bin/bash
# Run Flutter app with Android log filtering to suppress system spam
# Filters out known noisy tags from MIUI/Xiaomi devices
#
# Usage: ./run.sh [additional flutter run args]

echo "🚀 Running My Exchange with log filtering..."
echo "   Filters out InsetsSource, ROM debug tags, Chucker noise"

# Merge stderr into stdout, then filter out known noisy log lines
flutter run "$@" 2>&1 | grep -vE \
  "^[WDEI]/(InsetsSource|ViewRootImplStubImpl|MIUIInput|HandWritingStubImpl|PowerHalMgrImpl|BLASTBufferQueue|BufferQueueConsumer|InsetsAnimationCtrlImpl|InsetsController|WindowOnBackDispatcher|ForceDarkHelperStubImpl|RemoteInputConnectionImpl|CompatChangeReporter|BpBinder|AutofillManager|AssistStructure|InputConnectionAdaptor|ImeTracker|RenderInspector|VRI\[MainActivity\]|ActivityThread|SurfaceView|Activity)"
