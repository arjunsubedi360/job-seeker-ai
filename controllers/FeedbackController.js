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
