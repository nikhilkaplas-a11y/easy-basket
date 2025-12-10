import { Request, Response } from 'express';
import crypto from 'crypto';

import { AppDataSource } from '../config/database';
import { FCMService } from '../services/fcm.service';
import { User } from '../entities/User';
import { RefreshToken } from '../entities/RefreshToken';
import { AuthRequest } from '../middleware/auth.middleware';
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

      // Check database connection
      if (!AppDataSource.isInitialized) {
        console.error('❌ Database not initialized');
        res.status(500).json({ message: 'Database connection not available' });
        return;
      }

      console.log(`🔍 Verifying OTP for ${phoneNumber}...`);
      const userRepository = AppDataSource.getRepository(User);
      let user = await userRepository.findOneBy({ phoneNumber });
      console.log(`✅ User lookup completed: ${user ? 'found' : 'not found'}`);

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

      // Generate Access Token (short-lived: 15 minutes)
      const accessToken = jwt.sign(
        { userId: user.id, phoneNumber: user.phoneNumber, role: user.role },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '15m' } // Access token expires in 15 minutes
      );

      // Generate Refresh Token (long-lived: 30 days)
      const refreshTokenValue = crypto.randomBytes(64).toString('hex');
      const refreshTokenExpiry = new Date();
      refreshTokenExpiry.setDate(refreshTokenExpiry.getDate() + 30); // 30 days

      // Save refresh token to database
      console.log(`💾 Saving refresh token for user ${user.id}...`);
      const refreshTokenRepository = AppDataSource.getRepository(RefreshToken);
      const refreshToken = refreshTokenRepository.create({
        token: refreshTokenValue,
        userId: user.id,
        expiresAt: refreshTokenExpiry,
        isActive: true,
      });
      await refreshTokenRepository.save(refreshToken);
      console.log(`✅ Refresh token saved successfully`);

      res.json({
        message: 'Login successful',
        accessToken,
        refreshToken: refreshTokenValue,
        user: {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          email: user.email,
          birthday: user.birthday ? user.birthday.toISOString().split('T')[0] : null,
          role: user.role,
        },
      });
    } catch (error) {
      console.error('❌ Error in verify endpoint:', error);
      if (error instanceof Error) {
        console.error('Error message:', error.message);
        console.error('Error stack:', error.stack);
      }
      res.status(500).json({ 
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' && error instanceof Error ? error.message : undefined
      });
    }
  }

  static async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    const { name, email, birthday, fcmToken } = req.body;
    const userId = req.user?.id;

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

      if (name !== undefined) user.name = name;
      if (email !== undefined) user.email = email;
      if (birthday !== undefined) {
        // Parse birthday string to Date if provided, or set to null to clear
        if (birthday === null || birthday === '') {
          user.birthday = null;
        } else {
          user.birthday = new Date(birthday);
        }
      }
      if (fcmToken) user.fcmToken = fcmToken;

      await userRepository.save(user);

      res.json({
        message: 'Profile updated successfully',
        user: {
          id: user.id,
          phoneNumber: user.phoneNumber,
          name: user.name,
          email: user.email,
          birthday: user.birthday ? user.birthday.toISOString().split('T')[0] : null,
          role: user.role,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating profile' });
    }
  }

  static async refresh(req: Request, res: Response): Promise<void> {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      res.status(400).json({ message: 'Refresh token is required' });
      return;
    }

    try {
      const refreshTokenRepository = AppDataSource.getRepository(RefreshToken);
      const tokenRecord = await refreshTokenRepository.findOne({
        where: { token: refreshToken, isActive: true },
        relations: ['user'],
      });

      if (!tokenRecord) {
        res.status(401).json({ message: 'Invalid refresh token' });
        return;
      }

      // Check if token is expired
      if (new Date() > tokenRecord.expiresAt) {
        // Mark token as inactive
        tokenRecord.isActive = false;
        await refreshTokenRepository.save(tokenRecord);
        res.status(401).json({ message: 'Refresh token expired' });
        return;
      }

      // Check if user is active
      if (!tokenRecord.user.isActive) {
        res.status(401).json({ message: 'User account is inactive' });
        return;
      }

      // Generate new access token
      const accessToken = jwt.sign(
        {
          userId: tokenRecord.user.id,
          phoneNumber: tokenRecord.user.phoneNumber,
          role: tokenRecord.user.role,
        },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '15m' } // Access token expires in 15 minutes
      );

      res.json({
        message: 'Token refreshed successfully',
        accessToken,
        user: {
          id: tokenRecord.user.id,
          phoneNumber: tokenRecord.user.phoneNumber,
          name: tokenRecord.user.name,
          email: tokenRecord.user.email,
          role: tokenRecord.user.role,
        },
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Internal server error' });
    }
  }

  static async logout(req: Request, res: Response): Promise<void> {
    const { refreshToken } = req.body;
    const userId = (req as any).user?.id;

    try {
      if (refreshToken) {
        // Revoke refresh token
        const refreshTokenRepository = AppDataSource.getRepository(RefreshToken);
        const tokenRecord = await refreshTokenRepository.findOne({
          where: { token: refreshToken },
        });

        if (tokenRecord) {
          tokenRecord.isActive = false;
          await refreshTokenRepository.save(tokenRecord);
        }
      } else if (userId) {
        // Revoke all refresh tokens for this user
        const refreshTokenRepository = AppDataSource.getRepository(RefreshToken);
        await refreshTokenRepository.update(
          { userId, isActive: true },
          { isActive: false }
        );
      }

      res.json({ message: 'Logout successful' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Internal server error' });
    }
  }
}

