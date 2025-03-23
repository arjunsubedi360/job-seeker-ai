// controllers/JobController.js
import * as cheerio from 'cheerio';
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
