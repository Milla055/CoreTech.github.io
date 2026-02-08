import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router } from '@angular/router';
import { ProductService, Product } from '../services/product.service';
import { ProductcardComponent } from '../productcard/productcard.component';
import { FooterComponent } from "../footer/footer.component";
import { HeaderComponent } from "../header/header.component";

@Component({
  selector: 'app-productpage',
  standalone: true,
  imports: [CommonModule, ProductcardComponent, FooterComponent, HeaderComponent],
  templateUrl: './productpage.component.html',
  styleUrl: './productpage.component.css',
})
export class ProductpageComponent implements OnInit {
  products: Product[] = [];
  filteredProducts: Product[] = [];
  loading: boolean = true;
  error: string | null = null;

  // Category info
  categoryId: number = 1; // Graphics Cards default
  categoryName: string = 'Videókártyák';
  productCount: number = 0;

  // Search and filters
  searchQuery: string = '';
  selectedManufacturer: string = 'all';
  selectedSort: string = 'default';

  // Available manufacturers (will be populated from products)
  manufacturers: string[] = [];

  // Category name mapping
  private categoryNames: { [key: string]: string } = {
    'videókártya': 'Videókártyák',
    'processzor': 'Processzorok',
    'cpu': 'Processzorok',
    'memória': 'Memóriák',
    'ram': 'Memóriák',
    'alaplap': 'Alaplapok',
    'motherboard': 'Alaplapok',
    'ssd': 'SSD-k',
    'hdd': 'HDD-k',
    'merevlemez': 'Merevlemezek',
    'hűtés': 'Hűtések',
    'cooler': 'Hűtések',
    'tápegység': 'Tápegységek',
    'psu': 'Tápegységek',
    'gépház': 'Gépházak',
    'case': 'Gépházak',
    'egér': 'Egerek',
    'mouse': 'Egerek',
    'billentyűzet': 'Billentyűzetek',
    'keyboard': 'Billentyűzetek',
    'monitor': 'Monitorok',
    'fejhallgató': 'Fejhallgatók',
    'headset': 'Fejhallgatók',
    'mikrofon': 'Mikrofonok',
    'microphone': 'Mikrofonok'
  };

  constructor(
    private productService: ProductService,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Get query params from URL
    this.route.queryParams.subscribe(params => {
      this.searchQuery = params['search'] || '';
      this.categoryId = params['category'] ? +params['category'] : 1;
      
      // Set category name based on search query
      this.updateCategoryName();
      
      this.loadProducts();
    });
  }

  updateCategoryName(): void {
    if (this.searchQuery) {
      const searchLower = this.searchQuery.toLowerCase().trim();
      // Check if search query matches any category
      const matchedCategory = this.categoryNames[searchLower];
      if (matchedCategory) {
        this.categoryName = matchedCategory;
      } else {
        // Try partial match
        for (const key in this.categoryNames) {
          if (searchLower.includes(key) || key.includes(searchLower)) {
            this.categoryName = this.categoryNames[key];
            break;
          }
        }
      }
    } else {
      // Default category names by ID
      switch (this.categoryId) {
        case 1:
          this.categoryName = 'Videókártyák';
          break;
        case 2:
          this.categoryName = 'Processzorok';
          break;
        case 3:
          this.categoryName = 'Memóriák';
          break;
        default:
          this.categoryName = 'Termékek';
      }
    }
  }

  loadProducts(): void {
    this.loading = true;
    this.error = null;

    console.log('🔍 Loading products for category:', this.categoryId);
    console.log('🔍 Initial search query:', this.searchQuery);

    // Load products by category
    this.productService.getProductsByCategoryId(this.categoryId).subscribe({
      next: (data) => {
        console.log('✅ Products loaded from backend:', data.length, 'products');
        this.products = data;
        this.extractManufacturers();
        
        // DON'T apply search filter initially - show all products
        this.showAllProducts();
        
        this.loading = false;
      },
      error: (error) => {
        console.error('❌ Error loading products:', error);
        this.error = 'Nem sikerült betölteni a termékeket';
        this.loading = false;
      }
    });
  }

  extractManufacturers(): void {
    // Extract unique brand names from products
    const brandSet = new Set<string>();
    this.products.forEach(p => {
      if (p.brandId?.name) {
        brandSet.add(p.brandId.name);
      }
    });
    this.manufacturers = Array.from(brandSet).sort();
    console.log('🏭 Manufacturers found:', this.manufacturers);
  }

  showAllProducts(): void {
    // Show ALL products without any filters initially
    this.filteredProducts = [...this.products];
    this.productCount = this.filteredProducts.length;
    console.log('📦 Displaying all products:', this.productCount);
  }

  applyFilters(): void {
    let filtered = [...this.products];
    console.log('🔧 Applying filters to', filtered.length, 'products');

    // Apply search filter ONLY if user manually searches
    // (not from initial URL parameter)
    if (this.searchQuery && this.searchQuery.trim() !== '') {
      const query = this.searchQuery.toLowerCase().trim();
      console.log('🔍 Search filter:', query);
      filtered = filtered.filter(p => 
        p.name.toLowerCase().includes(query) ||
        (p.description && p.description.toLowerCase().includes(query)) ||
        (p.brandId?.name && p.brandId.name.toLowerCase().includes(query))
      );
      console.log('   → After search:', filtered.length, 'products');
    }

    // Apply manufacturer filter
    if (this.selectedManufacturer !== 'all') {
      console.log('🏭 Manufacturer filter:', this.selectedManufacturer);
      filtered = filtered.filter(p => 
        p.brandId?.name === this.selectedManufacturer
      );
      console.log('   → After manufacturer:', filtered.length, 'products');
    }

    // Apply sorting
    switch (this.selectedSort) {
      case 'price-asc':
        filtered.sort((a, b) => a.pPrice - b.pPrice);
        console.log('💰 Sorted by price ascending');
        break;
      case 'price-desc':
        filtered.sort((a, b) => b.pPrice - a.pPrice);
        console.log('💰 Sorted by price descending');
        break;
      case 'name-asc':
        filtered.sort((a, b) => a.name.localeCompare(b.name));
        console.log('🔤 Sorted by name A-Z');
        break;
      case 'name-desc':
        filtered.sort((a, b) => b.name.localeCompare(a.name));
        console.log('🔤 Sorted by name Z-A');
        break;
      default:
        // Keep original order
        break;
    }

    this.filteredProducts = filtered;
    this.productCount = filtered.length;
    console.log('✅ Final filtered products:', this.productCount);
  }

  onManufacturerChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    this.selectedManufacturer = select.value;
    console.log('🏭 Manufacturer changed to:', this.selectedManufacturer);
    this.applyFilters();
  }

  onSortChange(event: Event): void {
    const select = event.target as HTMLSelectElement;
    this.selectedSort = select.value;
    console.log('🔄 Sort changed to:', this.selectedSort);
    this.applyFilters();
  }

  onSearchFilter(): void {
    console.log('🔍 Manual search triggered');
    this.applyFilters();
  }

  clearFilters(): void {
    console.log('🗑️ Clearing all filters');
    this.selectedManufacturer = 'all';
    this.selectedSort = 'default';
    this.searchQuery = '';
    this.showAllProducts(); // Show all products again
  }
}