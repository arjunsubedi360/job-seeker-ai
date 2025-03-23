// models/Application.js
import mongoose from 'mongoose';

const applicationSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  job: { type: mongoose.Schema.Types.ObjectId, ref: 'Job' },
  status: { type: String, default: 'applied' },
  date: { type: Date, default: Date.now },
  notes: String,
});

export default mongoose.model('Application', applicationSchema);
