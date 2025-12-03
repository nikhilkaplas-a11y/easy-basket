import { AppDataSource } from '../config/database';
import { Category } from '../entities/Category';
import { Product } from '../entities/Product';

async function seed() {
  try {
    console.log('🌱 Starting database seed...');

    // Initialize database connection
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
      console.log('✅ Database connected');
    }

    const categoryRepository = AppDataSource.getRepository(Category);
    const productRepository = AppDataSource.getRepository(Product);

    // Clear existing data (optional - comment out if you want to keep existing data)
    // await productRepository.delete({});
    // await categoryRepository.delete({});
    // console.log('🗑️  Cleared existing data');

    // Create Categories
    const categories = [
      { name: 'Fruits & Vegetables', description: 'Fresh fruits and vegetables', imageUrl: 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=400' },
      { name: 'Dairy & Eggs', description: 'Milk, cheese, eggs and more', imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400' },
      { name: 'Beverages', description: 'Soft drinks, juices, tea, coffee', imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400' },
      { name: 'Snacks', description: 'Chips, biscuits, chocolates', imageUrl: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=400' },
      { name: 'Bakery', description: 'Bread, cakes, pastries', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400' },
      { name: 'Personal Care', description: 'Soap, shampoo, toothpaste', imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400' },
      { name: 'Household', description: 'Cleaning supplies, detergents', imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400' },
      { name: 'Spices & Masala', description: 'Indian spices and masalas', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
    ];

    const savedCategories: Category[] = [];

    for (const catData of categories) {
      let category = await categoryRepository.findOne({ where: { name: catData.name } });
      
      if (!category) {
        category = categoryRepository.create(catData);
        category = await categoryRepository.save(category);
        console.log(`✅ Created category: ${category.name}`);
      } else {
        console.log(`ℹ️  Category already exists: ${category.name}`);
      }
      
      savedCategories.push(category);
    }

    // Create Products
    const products = [
      // Fruits & Vegetables
      { name: 'Tomatoes', description: 'Fresh red tomatoes', price: 40, unit: 'kg', stock: 50, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1546093354-7eef13592681?w=400' },
      { name: 'Onions', description: 'Fresh onions', price: 30, unit: 'kg', stock: 100, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=400' },
      { name: 'Potatoes', description: 'Fresh potatoes', price: 25, unit: 'kg', stock: 80, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1518977822534-7049a61ee0c2?w=400' },
      { name: 'Bananas', description: 'Fresh yellow bananas', price: 60, unit: 'dozen', stock: 40, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400' },
      { name: 'Apples', description: 'Fresh red apples', price: 120, unit: 'kg', stock: 30, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400' },
      { name: 'Carrots', description: 'Fresh carrots', price: 50, unit: 'kg', stock: 45, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400' },
      { name: 'Spinach', description: 'Fresh spinach leaves', price: 35, unit: 'bunch', stock: 25, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400' },
      { name: 'Capsicum', description: 'Fresh green capsicum', price: 80, unit: 'kg', stock: 35, category: savedCategories[0], imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=400' },

      // Dairy & Eggs
      { name: 'Milk', description: 'Fresh full cream milk', price: 60, unit: 'liter', stock: 100, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400' },
      { name: 'Eggs', description: 'Farm fresh eggs', price: 90, unit: 'dozen', stock: 60, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400' },
      { name: 'Butter', description: 'Amul butter', price: 55, unit: 'pack', stock: 50, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7fe3e9c0d1?w=400' },
      { name: 'Paneer', description: 'Fresh cottage cheese', price: 300, unit: 'kg', stock: 20, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1618164436269-9205138291e0?w=400' },
      { name: 'Curd', description: 'Fresh curd', price: 50, unit: 'pack', stock: 40, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1606312619070-d48b4e6c3e1e?w=400' },
      { name: 'Cheese', description: 'Processed cheese slices', price: 120, unit: 'pack', stock: 30, category: savedCategories[1], imageUrl: 'https://images.unsplash.com/photo-1618164436269-9205138291e0?w=400' },

      // Beverages
      { name: 'Coca Cola', description: '1.5L bottle', price: 90, unit: 'bottle', stock: 80, category: savedCategories[2], imageUrl: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=400' },
      { name: 'Orange Juice', description: 'Fresh orange juice', price: 80, unit: 'pack', stock: 50, category: savedCategories[2], imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400' },
      { name: 'Tea', description: 'Premium tea leaves', price: 150, unit: 'pack', stock: 60, category: savedCategories[2], imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400' },
      { name: 'Coffee', description: 'Instant coffee powder', price: 200, unit: 'pack', stock: 45, category: savedCategories[2], imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400' },
      { name: 'Mineral Water', description: '1L bottle', price: 20, unit: 'bottle', stock: 150, category: savedCategories[2], imageUrl: 'https://images.unsplash.com/photo-1548839140-5a9415c5776a?w=400' },

      // Snacks
      { name: 'Lays Chips', description: 'Classic salted chips', price: 20, unit: 'pack', stock: 100, category: savedCategories[3], imageUrl: 'https://images.unsplash.com/photo-1613919113643-c6c0b0c5b3a3?w=400' },
      { name: 'Biscuits', description: 'Parle-G glucose biscuits', price: 30, unit: 'pack', stock: 80, category: savedCategories[3], imageUrl: 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400' },
      { name: 'Chocolate', description: 'Cadbury dairy milk', price: 50, unit: 'bar', stock: 70, category: savedCategories[3], imageUrl: 'https://images.unsplash.com/photo-1606312619070-d48b4e6c3e1e?w=400' },
      { name: 'Namkeen', description: 'Haldiram namkeen mix', price: 80, unit: 'pack', stock: 50, category: savedCategories[3], imageUrl: 'https://images.unsplash.com/photo-1613919113643-c6c0b0c5b3a3?w=400' },

      // Bakery
      { name: 'White Bread', description: 'Fresh white bread', price: 40, unit: 'loaf', stock: 60, category: savedCategories[4], imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400' },
      { name: 'Brown Bread', description: 'Whole wheat bread', price: 45, unit: 'loaf', stock: 50, category: savedCategories[4], imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400' },
      { name: 'Bun', description: 'Fresh buns', price: 30, unit: 'pack', stock: 40, category: savedCategories[4], imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400' },
      { name: 'Cake', description: 'Chocolate cake', price: 250, unit: 'piece', stock: 15, category: savedCategories[4], imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400' },

      // Personal Care
      { name: 'Soap', description: 'Lux soap', price: 35, unit: 'piece', stock: 100, category: savedCategories[5], imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400' },
      { name: 'Shampoo', description: 'Pantene shampoo', price: 180, unit: 'bottle', stock: 40, category: savedCategories[5], imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400' },
      { name: 'Toothpaste', description: 'Colgate toothpaste', price: 90, unit: 'tube', stock: 60, category: savedCategories[5], imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400' },
      { name: 'Face Wash', description: 'Himalaya face wash', price: 120, unit: 'bottle', stock: 35, category: savedCategories[5], imageUrl: 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400' },

      // Household
      { name: 'Detergent', description: 'Surf excel', price: 200, unit: 'pack', stock: 50, category: savedCategories[6], imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400' },
      { name: 'Dish Soap', description: 'Vim dish wash', price: 60, unit: 'bottle', stock: 45, category: savedCategories[6], imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400' },
      { name: 'Floor Cleaner', description: 'Harpic floor cleaner', price: 150, unit: 'bottle', stock: 30, category: savedCategories[6], imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400' },
      { name: 'Tissue Paper', description: 'Soft tissue paper', price: 80, unit: 'pack', stock: 60, category: savedCategories[6], imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400' },

      // Spices & Masala
      { name: 'Turmeric Powder', description: 'Pure turmeric powder', price: 120, unit: 'kg', stock: 40, category: savedCategories[7], imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
      { name: 'Red Chili Powder', description: 'Spicy red chili powder', price: 150, unit: 'kg', stock: 35, category: savedCategories[7], imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
      { name: 'Garam Masala', description: 'Premium garam masala', price: 200, unit: 'pack', stock: 50, category: savedCategories[7], imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
      { name: 'Cumin Seeds', description: 'Whole cumin seeds', price: 180, unit: 'kg', stock: 30, category: savedCategories[7], imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
      { name: 'Coriander Powder', description: 'Ground coriander', price: 140, unit: 'kg', stock: 40, category: savedCategories[7], imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=400' },
    ];

    let createdCount = 0;
    let skippedCount = 0;

    for (const productData of products) {
      const existingProduct = await productRepository.findOne({
        where: { name: productData.name },
      });

      if (!existingProduct) {
        const product = productRepository.create({
          ...productData,
          isAvailable: true,
        });
        await productRepository.save(product);
        console.log(`✅ Created product: ${product.name} (₹${product.price})`);
        createdCount++;
      } else {
        console.log(`ℹ️  Product already exists: ${productData.name}`);
        skippedCount++;
      }
    }

    console.log('\n📊 Seed Summary:');
    console.log(`   Categories: ${savedCategories.length}`);
    console.log(`   Products created: ${createdCount}`);
    console.log(`   Products skipped: ${skippedCount}`);
    console.log('\n✅ Database seed completed successfully!');

    await AppDataSource.destroy();
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

// Run seed if executed directly
if (require.main === module) {
  seed();
}

export default seed;

