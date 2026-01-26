import { Component, Input, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ProductService, Product } from '../services/product.service';

@Component({
  selector: 'app-productcard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './productcard.component.html',
  styleUrl: './productcard.component.css'
})
export class ProductcardComponent implements OnInit {
  @Input() productId?: number;
  @Input() useMockData: boolean = true; // Set to true by default for testing
  
  product: Product | null = null;
  loading: boolean = true;
  error: string | null = null;

  // Mock products data - Graphics Cards
  private mockProducts: Product[] = [
    {
      id: 1,
      name: 'NVIDIA GeForce RTX 4090',
      price: 1599.99,
      pPrice: 1499.99,
      stock: 15,
      imageUrl: 'assets/mockproduct1.png',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 1, name: 'NVIDIA' }
    },
    {
      id: 2,
      name: 'AMD Radeon RX 7900 XTX',
      description: 'High-performance gaming with 24GB GDDR6 memory',
      price: 999.99,
      pPrice: 899.99,
      stock: 20,
      imageUrl: 'https://m.media-amazon.com/images/I/81bmQkGPySL._AC_SL1500_.jpg',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 2, name: 'AMD' }
    },
    {
      id: 3,
      name: 'NVIDIA GeForce RTX 4080',
      description: 'Exceptional performance for gamers and creators',
      price: 1199.99,
      pPrice: 1099.99,
      stock: 25,
      imageUrl: 'https://m.media-amazon.com/images/I/81bz7C3dOWL._AC_SL1500_.jpg',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 1, name: 'NVIDIA' }
    },
    {
      id: 4,
      name: 'NVIDIA GeForce RTX 4070 Ti',
      description: 'Incredible gaming experience with ray tracing',
      price: 799.99,
      pPrice: 749.99,
      stock: 30,
      imageUrl: 'https://m.media-amazon.com/images/I/71Q0xvoLgOL._AC_SL1280_.jpg',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 1, name: 'NVIDIA' }
    },
    {
      id: 5,
      name: 'AMD Radeon RX 7800 XT',
      description: '1440p gaming powerhouse with 16GB memory',
      price: 499.99,
      pPrice: 449.99,
      stock: 40,
      imageUrl: 'https://m.media-amazon.com/images/I/71nBhZKP4LL._AC_SL1280_.jpg',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 2, name: 'AMD' }
    },
    {
      id: 6,
      name: 'NVIDIA GeForce RTX 3060',
      description: 'Great 1080p gaming performance',
      price: 329.99,
      pPrice: 299.99,
      stock: 50,
      imageUrl: 'https://m.media-amazon.com/images/I/81bhFYS22eL._AC_SL1500_.jpg',
      categoryId: { id: 2, name: 'Graphics Cards' },
      brandId: { id: 1, name: 'NVIDIA' }
    }
  ];

  constructor(private productService: ProductService) {}

  ngOnInit(): void {
    if (this.useMockData) {
      this.loadMockProduct();
    } else if (this.productId) {
      this.loadProduct(this.productId);
    } else {
      this.loadDefaultProduct();
    }
  }

  loadMockProduct(): void {
    // Simulate network delay
    setTimeout(() => {
      // If productId is specified, find that product, otherwise use first one
      if (this.productId) {
        this.product = this.mockProducts.find(p => p.id === this.productId) || this.mockProducts[0];
      } else {
        // Use a random product or the first one
        this.product = this.mockProducts[0];
      }
      this.loading = false;
      console.log('Mock product loaded:', this.product);
    }, 500);
  }

  loadProduct(id: number): void {
    this.loading = true;
    this.productService.getProductById(id).subscribe(
      (data) => {
        console.log('Product loaded:', data);
        this.product = data;
        this.loading = false;
      },
      (error) => {
        console.error('Error loading product:', error);
        console.error('Error details:', error.error);
        console.error('Status:', error.status);
        console.error('URL tried:', error.url);
        this.error = 'Failed to load product - Check console for details';
        this.loading = false;
      }
    );
  }

  loadDefaultProduct(): void {
    this.loading = true;
    this.productService.getAllProducts().subscribe(
      (products) => {
        console.log('Products loaded:', products);
        if (products && products.length > 0) {
          this.product = products[0];
        } else {
          this.error = 'No products available';
        }
        this.loading = false;
      },
      (error) => {
        console.error('Error loading products:', error);
        console.error('Error details:', error.error);
        console.error('Status:', error.status);
        console.error('URL tried:', error.url);
        this.error = 'Failed to load products - Check console for details';
        this.loading = false;
      }
    );
  }

  addToCart(): void {
    if (this.product) {
      if (this.useMockData) {
        console.log('Adding to cart (mock mode):', this.product.name);
        alert(`${this.product.name} hozzáadva a kosárhoz! (Mock mode)`);
        return;
      }

      this.productService.addToCart(this.product.id, 1).subscribe(
        (response) => {
          console.log('Product added to cart:', response);
          alert('Termék hozzáadva a kosárhoz!');
        },
        (error) => {
          console.error('Error adding to cart:', error);
          alert('Hiba történt a kosárhoz adás során!');
        }
      );
    }
  }

  formatPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  hasDiscount(): boolean {
    return this.product ? this.product.pPrice < this.product.price : false;
  }

  // Helper method to get a specific mock product by ID
  getMockProductById(id: number): Product | null {
    return this.mockProducts.find(p => p.id === id) || null;
  }
}