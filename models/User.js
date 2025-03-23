// models/User.js
import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  cv: {
    personal: String,
    education: String,
    experience: String,
    skills: String,
  },
});

export default mongoose.model('User', userSchema);
