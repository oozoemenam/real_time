const { readFileSync } = require("fs");
const { createServer } = require("http");
const { Server } = require("socket.io");

const httpServer = createServer((req, res) => {
  if (req.url !== "/") {
    res.writeHead(404);
    res.end("Not found");
    return;
  }
  res.end('content');
});

const IO = new Server(httpServer, {});

const port = 5000;
httpServer.listen(port, () => {
    console.log(`listening on port ${port}`);
});

IO.use((socket, next) => {
  if (socket.handshake.query) {
    console.log(socket.handshake.query);
    let fromId = socket.handshake.query.fromId;
    socket.user = fromId;
    next();
  }
});

IO.on("connection", (socket) => {
  console.log(socket.user, "Connected");
  socket.join(socket.user);

  socket.on("makeCall", ({toId, sdpOffer}) => {
    console.log(`makeCall ${toId} ${sdpOffer}`);
    socket.to(toId).emit("newCall", {
      fromId: socket.user,
      sdpOffer: sdpOffer,
    });
  });

  socket.on("answerCall", ({fromId, sdpAnswer}) => {
    console.log(`answerCall ${fromId} ${sdpAnswer}`);
    socket.to(fromId).emit("callAnswered", {
      to: socket.user,
      sdpAnswer: sdpAnswer,
    });
  });

  socket.on("IceCandidate", ({toId, iceCandidate}) => {
   console.log(`IceCandidate ${toId} ${iceCandidate}`);
   socket.to(toId).emit("IceCandidate", {
      sender: socket.user,
      iceCandidate: iceCandidate,
    });
  });
});