import { Request, Response } from 'express';

import { AppDataSource } from '../config/database';
import { FCMService } from '../services/fcm.service';
import { User } from '../entities/User';
import jwt from 'jsonwebtoken';

export class AuthController {
  static async login(req: Request, res: Response): Promise<void> {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
      res.status(400).json({ message: 'Phone number is required' });
      return;
    }

    try {
      // OTP is always 1234 for all users (no SMS provider needed)
      console.log(`OTP request for ${phoneNumber}. Use OTP: 1234`);

      res.json({ message: 'OTP sent successfully. Use 1234 for testing.' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error sending OTP' });
    }
  }

  static async verify(req: Request, res: Response): Promise<void> {
    const { phoneNumber, otp, fcmToken } = req.body;

    if (!phoneNumber || !otp) {
      res.status(400).json({ message: 'Phone number and OTP are required' });
      return;
    }

    try {
      // Accept OTP 1234 for all users (no verification needed)
      if (otp !== '1234') {
        res.status(400).json({ message: 'Invalid OTP. Please use 1234' });
        return;
      }

      const userRepository = AppDataSource.getRepository(User);
      let user = await userRepository.findOneBy({ phoneNumber });

      if (!user) {
        user = userRepository.create({ phoneNumber });
        await userRepository.save(user);
      } else {
        // Update FCM token if provided
        if (fcmToken) {
          user.fcmToken = fcmToken;
          await userRepository.save(user);
        }
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, phoneNumber: user.phoneNumber, role: user.role },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '30d' }
      );

      res.json({
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          email: user.email,
          role: user.role,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Internal server error' });
    }
  }

  static async updateProfile(req: Request, res: Response): Promise<void> {
    const { name, email, fcmToken } = req.body;
    const userId = (req as any).user?.id;

    if (!userId) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    try {
      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id: userId });

      if (!user) {
        res.status(404).json({ message: 'User not found' });
        return;
      }

      if (name) user.name = name;
      if (email) user.email = email;
      if (fcmToken) user.fcmToken = fcmToken;

      await userRepository.save(user);

      res.json({
        message: 'Profile updated successfully',
        user: {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          email: user.email,
          role: user.role,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating profile' });
    }
  }
}

