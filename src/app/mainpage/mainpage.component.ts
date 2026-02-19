import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { ProductcardComponent } from "../productcard/productcard.component";
import { ProductService, Product } from '../services/product.service';

@Component({
  selector: 'app-mainpage',
  standalone: true,
  imports: [CommonModule, HeaderComponent, FooterComponent, RouterLink, ProductcardComponent],
  templateUrl: './mainpage.component.html',
  styleUrl: './mainpage.component.css',
})
export class MainpageComponent implements OnInit {
  discountProducts: Product[] = [];
  loading: boolean = true;

  constructor(
    private productService: ProductService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadDiscountProducts();
  }

  loadDiscountProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        // Same seeded random as discounts page - 3 day rotation
        const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
        let seed = Math.floor(daysSinceEpoch / 3);

        const rng = () => {
          seed = (seed * 1664525 + 1013904223) & 0xffffffff;
          return (seed >>> 0) / 0xffffffff;
        };

        const shuffled = [...products];
        for (let i = shuffled.length - 1; i > 0; i--) {
          const j = Math.floor(rng() * (i + 1));
          [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
        }

        // Take first 8 products
        this.discountProducts = shuffled.slice(0, 8);
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading products:', err);
        this.loading = false;
      }
    });
  }

  goToDiscounts(): void {
    this.router.navigate(['/discounts']);
  }
}