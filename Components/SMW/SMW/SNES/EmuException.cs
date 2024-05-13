using System;
using System.Runtime.Serialization;

namespace SNES {
    [Serializable]
    internal class EmuException : Exception {
        public EmuException() {
        }

        public EmuException(string message) : base(message) {
        }

        public EmuException(string message, Exception innerException) : base(message, innerException) {
        }

        protected EmuException(SerializationInfo info, StreamingContext context) : base(info, context) {
        }
    }
}