#!/bin/bash

# Create the job-seeker-ai directory if it doesn't exist
mkdir -p ~/Desktop/job-seeker-ai

# Change to the job-seeker-ai directory
cd ~/Desktop/job-seeker-ai || { echo "Failed to change to job-seeker-ai directory!"; exit 1; }

# Create the necessary subdirectories
mkdir -p models controllers views public

# Move existing app.js and package.json into job-seeker-ai if they are on the Desktop
[ -f ~/Desktop/app.js ] && mv ~/Desktop/app.js .
[ -f ~/Desktop/package.json ] && mv ~/Desktop/package.json .

# Create models/User.js
cat << 'EOF' > models/User.js
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
EOF

# Create models/Job.js
cat << 'EOF' > models/Job.js
// models/Job.js
import mongoose from 'mongoose';

const jobSchema = new mongoose.Schema({
  title: String,
  requirements: String,
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
});

export default mongoose.model('Job', jobSchema);
EOF

# Create models/Application.js
cat << 'EOF' > models/Application.js
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
EOF

# Create controllers/AuthController.js
cat << 'EOF' > controllers/AuthController.js
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
EOF

# Create controllers/CVController.js
cat << 'EOF' > controllers/CVController.js
// controllers/CVController.js
import multer from 'multer';
import pdfParse from 'pdf-parse';
import mammoth from 'mammoth';
import User from '../models/User.js';

const upload = multer({ storage: multer.memoryStorage() });

class CVController {
  static uploadCV = upload.single('cv');

  static async processCV(req, res) {
    const file = req.file;
    let text;
    if (file.mimetype === 'application/pdf') {
      const data = await pdfParse(file.buffer);
      text = data.text;
    } else if (file.mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      const data = await mammoth.extractRawText({ buffer: file.buffer });
      text = data.value;
    } else {
      return res.status(400).send('Unsupported file type');
    }
    const cvData = {
      personal: text.match(/Name: (.+)/)?.[1] || '',
      education: text.match(/Education: (.+)/)?.[1] || '',
      experience: text.match(/Experience: (.+)/)?.[1] || '',
      skills: text.match(/Skills: (.+)/)?.[1] || '',
    };
    await User.findByIdAndUpdate(req.user.id, { cv: cvData });
    res.redirect('/dashboard');
  }
}

export default CVController;
EOF

# Create controllers/FeedbackController.js
cat << 'EOF' > controllers/FeedbackController.js
// controllers/FeedbackController.js
import { Configuration, OpenAIApi } from 'openai';
import User from '../models/User.js';

const configuration = new Configuration({ apiKey: 'your-openai-api-key' });
const openai = new OpenAIApi(configuration);

class FeedbackController {
  static async analyzeCV(req, res) {
    const user = await User.findById(req.user.id);
    const cvText = JSON.stringify(user.cv);
    const prompt = `Analyze this CV and provide feedback on structure, keywords, and missing information:\n\n${cvText}`;
    const response = await openai.createCompletion({
      model: 'text-davinci-003',
      prompt,
      max_tokens: 200,
    });
    const feedback = response.data.choices[0].text.trim();
    res.render('feedback', { feedback });
  }
}

export default FeedbackController;
EOF

# Create controllers/JobController.js
cat << 'EOF' > controllers/JobController.js
// controllers/JobController.js
import cheerio from 'cheerio';
import axios from 'axios';
import Job from '../models/Job.js';
import User from '../models/User.js';

class JobController {
  static async submitJob(req, res) {
    let jobText;
    if (req.body.url) {
      const { data } = await axios.get(req.body.url);
      const $ = cheerio.load(data);
      jobText = $('body').text();
    } else {
      return res.status(400).send('Please provide a job URL');
    }
    const jobData = {
      title: jobText.match(/Title: (.+)/)?.[1] || 'Unknown Title',
      requirements: jobText.match(/Requirements: (.+)/)?.[1] || '',
      user: req.user.id,
    };
    await Job.create(jobData);
    res.redirect('/jobs');
  }

  static async matchJob(req, res) {
    const user = await User.findById(req.user.id);
    const job = await Job.findById(req.params.jobId);
    const cvSkills = user.cv.skills.split(', ');
    const jobRequirements = job.requirements.split(', ');
    const matchedSkills = cvSkills.filter(skill => jobRequirements.includes(skill));
    const matchScore = (matchedSkills.length / jobRequirements.length) * 100;
    res.render('match', { matchScore, job, matchedSkills });
  }
}

export default JobController;
EOF

# Create controllers/ApplicationController.js
cat << 'EOF' > controllers/ApplicationController.js
// controllers/ApplicationController.js
import { Configuration, OpenAIApi } from 'openai';
import User from '../models/User.js';
import Job from '../models/Job.js';

const configuration = new Configuration({ apiKey: 'your-openai-api-key' });
const openai = new OpenAIApi(configuration);

class ApplicationController {
  static async generateCoverLetter(req, res) {
    const user = await User.findById(req.user.id);
    const job = await Job.findById(req.params.jobId);
    const prompt = `Write a cover letter for the job titled "${job.title}" with requirements "${job.requirements}" using this CV:\n\n${JSON.stringify(user.cv)}`;
    const response = await openai.createCompletion({
      model: 'text-davinci-003',
      prompt,
      max_tokens: 500,
    });
    const coverLetter = response.data.choices[0].text.trim();
    const missingSkills = job.requirements.split(', ').filter(req => !user.cv.skills.includes(req));
    res.render('coverLetter', { coverLetter, job, suggestions: missingSkills });
  }
}

export default ApplicationController;
EOF

# Create controllers/ApplicationTracker.js
cat << 'EOF' > controllers/ApplicationTracker.js
// controllers/ApplicationTracker.js
import Application from '../models/Application.js';

class ApplicationTracker {
  static async applyToJob(req, res) {
    const application = new Application({
      user: req.user.id,
      job: req.params.jobId,
      status: 'applied',
      date: new Date(),
    });
    await application.save();
    res.redirect('/applications');
  }

  static async updateApplication(req, res) {
    await Application.findByIdAndUpdate(req.params.applicationId, {
      status: req.body.status,
      notes: req.body.notes,
    });
    res.redirect('/applications');
  }
}

export default ApplicationTracker;
EOF

# Create views/feedback.ejs
cat << 'EOF' > views/feedback.ejs
<!DOCTYPE html>
<html>
<head>
  <title>CV Feedback</title>
</head>
<body>
  <h1>CV Feedback</h1>
  <p><%= feedback %></p>
  <a href="/dashboard">Back to Dashboard</a>
</body>
</html>
EOF

# Create views/match.ejs
cat << 'EOF' > views/match.ejs
<!DOCTYPE html>
<html>
<head>
  <title>Job Match</title>
</head>
<body>
  <h1>Match Results for <%= job.title %></h1>
  <p>Match Score: <%= matchScore %>%</p>
  <p>Matched Skills: <%= matchedSkills.join(', ') %></p>
  <a href="/jobs">Back to Jobs</a>
</body>
</html>
EOF

# Create views/coverLetter.ejs
cat << 'EOF' > views/coverLetter.ejs
<!DOCTYPE html>
<html>
<head>
  <title>Cover Letter</title>
</head>
<body>
  <h1>Cover Letter for <%= job.title %></h1>
  <pre><%= coverLetter %></pre>
  <h2>Suggestions</h2>
  <ul>
    <% suggestions.forEach(skill => { %>
      <li>Add skill: <%= skill %></li>
    <% }) %>
  </ul>
  <a href="/applications">Back to Applications</a>
</body>
</html>
EOF

echo "All files have been created and populated with content in the job-seeker-ai directory!"
