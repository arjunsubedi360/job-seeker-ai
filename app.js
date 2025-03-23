import express from 'express';
import mongoose from 'mongoose';
import session from 'express-session';
import passport from 'passport';
import LocalStrategy from 'passport-local';
import User from './models/User.js';
import AuthController from './controllers/AuthController.js';
import CVController from './controllers/CVController.js';
import FeedbackController from './controllers/FeedbackController.js';
import JobController from './controllers/JobController.js';
import ApplicationController from './controllers/ApplicationController.js';
import ApplicationTracker from './controllers/ApplicationTracker.js';

const app = express();

// Middleware
app.use(express.urlencoded({ extended: true }));
app.use(session({ secret: 'your-secret-key', resave: false, saveUninitialized: false }));
app.use(passport.initialize());
app.use(passport.session());
app.set('view engine', 'ejs');
app.use(express.static('public'));

// Passport configuration
passport.use(new LocalStrategy(User.authenticate()));
passport.serializeUser(User.serializeUser());
passport.deserializeUser(User.deserializeUser());

// MongoDB connection
mongoose.connect('mongodb://localhost/job-seeker-ai', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Routes
app.post('/register', AuthController.register);
app.post('/login', AuthController.login);
app.get('/logout', AuthController.logout);
app.post('/cv/upload', CVController.uploadCV, CVController.processCV);
app.get('/cv/analyze', FeedbackController.analyzeCV);
app.post('/jobs/submit', JobController.submitJob);
app.get('/jobs/:jobId/match', JobController.matchJob);
app.get('/applications/:jobId/generate', ApplicationController.generateCoverLetter);
app.post('/applications/:jobId/apply', ApplicationTracker.applyToJob);
app.post('/applications/:applicationId/update', ApplicationTracker.updateApplication);

// Basic route for testing
app.get('/', (req, res) => res.send('Welcome to Job Seeker AI'));

app.listen(3000, () => console.log('Server running on port 3000'));