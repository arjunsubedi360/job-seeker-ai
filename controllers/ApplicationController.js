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
