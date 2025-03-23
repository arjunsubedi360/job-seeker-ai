// controllers/AuthController.js
import passport from 'passport';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

class AuthController {
  static async register(req, res) {
    const { username, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ username, password: hashedPassword });
    try {
      await user.save();
      res.redirect('/login');
    } catch (error) {
      res.status(400).send('Registration failed');
    }
  }

  static login(req, res, next) {
    passport.authenticate('local', (err, user, info) => {
      if (err) return next(err);
      if (!user) return res.status(401).send(info.message);
      const token = jwt.sign({ id: user._id }, 'your-secret-key');
      res.cookie('token', token).redirect('/dashboard');
    })(req, res, next);
  }

  static logout(req, res) {
    res.clearCookie('token').redirect('/');
  }
}

export default AuthController;
