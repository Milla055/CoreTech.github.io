import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { FooterComponent } from '../footer/footer.component';
import { BrandService, Brand } from '../services/brand.service';

@Component({
  selector: 'app-brandlogothing',
  providers: [BrandService],
  imports: [CommonModule, HeaderComponent, FooterComponent],
  templateUrl: './brandlogothing.component.html',
  styleUrls: ['./brandlogothing.component.css'],
})
export class BrandlogothingComponent implements OnInit {
  brands: Brand[] = [];
  loading = true;
  error = false;

  constructor(
    private brandService: BrandService,
    private router: Router
  ) {}

  ngOnInit() {
    this.brandService.getAllBrands().subscribe({
      next: (brands) => {
        this.brands = brands;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error loading brands:', err);
        this.error = true;
        this.loading = false;
      }
    });
  }

  selectBrand(brand: Brand) {
    this.router.navigate(['/products'], {
      queryParams: {
        brand: brand.id,
        brandName: brand.name
      }
    });
  }
}