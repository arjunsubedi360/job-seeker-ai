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
