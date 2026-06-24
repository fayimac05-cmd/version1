let ioInstance = null;
const connectedUsers = {};

function init(io) {
  ioInstance = io;
}

function getIO() {
  return ioInstance;
}

function registerUser(userId, socketId) {
  connectedUsers[userId] = socketId;
}

function unregisterUser(userId) {
  delete connectedUsers[userId];
}

function emitToUser(userId, event, data) {
  if (!ioInstance) return;
  const socketId = connectedUsers[userId];
  if (socketId) ioInstance.to(socketId).emit(event, data);
}

function emitToCanal(canalId, event, data) {
  if (ioInstance) ioInstance.to(`canal_${canalId}`).emit(event, data);
}

function emitToEtablissement(etablissementId, event, data) {
  if (ioInstance) ioInstance.to(`etablissement_${etablissementId}`).emit(event, data);
}

function emitToFiliere(filiere, event, data) {
  if (filiere && ioInstance) ioInstance.to(`filiere_${filiere}`).emit(event, data);
}

function broadcast(event, data) {
  if (ioInstance) ioInstance.emit(event, data);
}

module.exports = {
  init,
  getIO,
  registerUser,
  unregisterUser,
  emitToUser,
  emitToCanal,
  emitToEtablissement,
  emitToFiliere,
  broadcast,
  connectedUsers,
};
