import { Response } from 'express';
import { AppDataSource } from '../config/database';
import { Address } from '../entities/Address';
import { User } from '../entities/User';
import { AuthRequest } from '../middleware/auth.middleware';

export class AddressController {
  static async getUserAddresses(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);
      const addresses = await addressRepository.find({
        where: { user: { id: userId } },
        order: { isDefault: 'DESC', createdAt: 'DESC' },
      });

      res.json(addresses);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error fetching addresses' });
    }
  }

  static async createAddress(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const {
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        landmark,
        isDefault,
        latitude,
        longitude,
        tag,
      } = req.body;

      if (!addressLine1 || !city || !state || !pincode) {
        res.status(400).json({
          message: 'Address line 1, city, state, and pincode are required',
        });
        return;
      }

      const userRepository = AppDataSource.getRepository(User);
      const user = await userRepository.findOneBy({ id: userId });

      if (!user) {
        res.status(404).json({ message: 'User not found' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);

      // If setting as default, unset other defaults
      if (isDefault) {
        await addressRepository.update(
          { user: { id: userId } },
          { isDefault: false }
        );
      }

      const address = addressRepository.create({
        user,
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        landmark,
        isDefault: isDefault || false,
        latitude,
        longitude,
        tag: tag || null,
      });

      await addressRepository.save(address);
      res.status(201).json(address);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error creating address' });
    }
  }

  static async updateAddress(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);
      const address = await addressRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
      });

      if (!address) {
        res.status(404).json({ message: 'Address not found' });
        return;
      }

      const {
        addressLine1,
        addressLine2,
        city,
        state,
        pincode,
        landmark,
        isDefault,
        latitude,
        longitude,
        tag,
      } = req.body;

      if (addressLine1) address.addressLine1 = addressLine1;
      if (addressLine2 !== undefined) address.addressLine2 = addressLine2;
      if (city) address.city = city;
      if (state) address.state = state;
      if (pincode) address.pincode = pincode;
      if (landmark !== undefined) address.landmark = landmark;
      if (latitude !== undefined) address.latitude = latitude;
      if (longitude !== undefined) address.longitude = longitude;
      if (tag !== undefined) address.tag = tag;

      if (isDefault === true) {
        await addressRepository.update(
          { user: { id: userId } },
          { isDefault: false }
        );
        address.isDefault = true;
      }

      await addressRepository.save(address);
      res.json(address);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error updating address' });
    }
  }

  static async deleteAddress(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        res.status(401).json({ message: 'Authentication required' });
        return;
      }

      const addressRepository = AppDataSource.getRepository(Address);
      const address = await addressRepository.findOne({
        where: { id: Number(id), user: { id: userId } },
      });

      if (!address) {
        res.status(404).json({ message: 'Address not found' });
        return;
      }

      await addressRepository.remove(address);
      res.json({ message: 'Address deleted successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Error deleting address' });
    }
  }
}

