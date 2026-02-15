import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../services/auth.service';
import { AdminService, AdminUser, Order, Review } from '../services/admin.service';
import { ProductService, Product } from '../services/product.service';

@Component({
  selector: 'app-adminpage',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './adminpage.component.html',
  styleUrl: './adminpage.component.css',
})
export class AdminpageComponent implements OnInit {
  activeMenu: string = 'dashboard';
  today: string = '';
  loading: boolean = true;
  
  // Stats data
  stats = {
    users: 0,
    orders: 0,
    revenue: 0,
    profit: 0,
    admins: 0,
    subscribers: 0
  };

  // Admin list
  admins: AdminUser[] = [];

  // Chart data
  chartData: { month: string; sales: number; orders: number }[] = [];

  // Recent orders
  recentOrders: Order[] = [];

  // Top products
  topProducts: { id: number; name: string; sales: number; revenue: number }[] = [];

  // All users for users tab
  allUsers: any[] = [];
  filteredUsers: any[] = [];
  userSearchQuery: string = '';

  // All orders for orders tab
  allOrders: Order[] = [];
  filteredOrders: Order[] = [];
  orderSearchQuery: string = '';
  orderStatusFilter: string = 'all';

  // Reviews for reviews tab
  reviews: Review[] = [];
  filteredReviews: Review[] = [];
  reviewSearchQuery: string = '';

  // Products for products tab
  products: Product[] = [];
  filteredProducts: Product[] = [];
  productSearchQuery: string = '';

  // Product form for adding/editing
  showProductForm: boolean = false;
  editingProduct: boolean = false;
  productForm = {
    id: 0,
    categoryId: 1,
    brandId: 1,
    name: '',
    description: '',
    price: 0,
    stock: 0,
    imageUrl: ''
  };

  constructor(
    private router: Router,
    private authService: AuthService,
    private adminService: AdminService,
    private productService: ProductService
  ) {}

  ngOnInit(): void {
    // Check if user is admin
    const user = this.authService.getCurrentUser();
    if (!user || user.role?.toLowerCase() !== 'admin') {
      this.router.navigate(['/mainpage']);
      return;
    }
    
    // Set today's date
    const now = new Date();
    const days = ['vasárnap', 'hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat'];
    this.today = `${now.getFullYear()}. ${String(now.getMonth() + 1).padStart(2, '0')}. ${String(now.getDate()).padStart(2, '0')}. ${days[now.getDay()]}`;

    this.loadDashboardData();
  }

  loadDashboardData(): void {
    this.loading = true;

    // 1. Felhasználók számának lekérése
    this.adminService.getUserCount().subscribe({
      next: (count) => {
        console.log('👥 User count:', count);
        this.stats.users = count;
      },
      error: (err) => {
        console.error('❌ Error loading user count:', err);
      }
    });

    // 2. Adminok betöltése dinamikusan
    this.loadAdmins();

    // 3. További dashboard adatok betöltése
    this.loadChartData();
    this.loadRecentOrders();
    this.loadTopProducts();
    
    // 4. Stats betöltése (orders, revenue, profit)
    this.loadStats();
    
    this.loading = false;
  }

  loadStats(): void {
    console.log('📊 Loading dashboard stats...');
    
    // Get admin stats from backend
    this.adminService.getDashboardStats().subscribe({
      next: (stats) => {
        console.log('✅ Admin stats loaded:', stats);
        
        // Update stats object
        if (stats.totalOrders !== undefined) {
          this.stats.orders = stats.totalOrders;
        }
        if (stats.totalRevenue !== undefined) {
          this.stats.revenue = stats.totalRevenue;
        }
        if (stats.totalProfit !== undefined) {
          this.stats.profit = stats.totalProfit;
        }
      },
      error: (err) => {
        console.error('❌ Error loading stats:', err);
      }
    });
  }

  loadAdmins(): void {
    console.log('🔍 Loading admins...');
    this.adminService.getAdminUsers().subscribe({
      next: (admins) => {
        console.log('👑 Admins loaded:', admins);
        this.admins = admins;
        this.stats.admins = admins.length;
      },
      error: (err) => {
        console.error('❌ Error loading admins:', err);
        this.admins = [];
        this.stats.admins = 0;
      }
    });
  }

  loadChartData(): void {
    this.adminService.getMonthlySalesData().subscribe({
      next: (data) => {
        console.log('📊 Chart data loaded:', data);
        this.chartData = data;
      },
      error: (err) => {
        console.error('❌ Error loading chart data:', err);
      }
    });
  }

  loadRecentOrders(): void {
    this.adminService.getRecentOrders().subscribe({
      next: (orders) => {
        console.log('📦 Recent orders loaded:', orders);
        this.recentOrders = orders.slice(0, 5);
      },
      error: (err) => {
        console.error('❌ Error loading recent orders:', err);
      }
    });
  }

  loadTopProducts(): void {
    this.adminService.getTopProducts().subscribe({
      next: (products) => {
        console.log('🏆 Top products loaded:', products);
        this.topProducts = products;
      },
      error: (err) => {
        console.error('❌ Error loading top products:', err);
      }
    });
  }

  setActiveMenu(menu: string): void {
    this.activeMenu = menu;

    // Load specific data for each tab
    if (menu === 'users' && this.allUsers.length === 0) {
      this.loadAllUsers();
    } else if (menu === 'orders' && this.allOrders.length === 0) {
      this.loadAllOrders();
    } else if (menu === 'reviews' && this.reviews.length === 0) {
      this.loadAllReviews();
    } else if (menu === 'products' && this.products.length === 0) {
      this.loadAllProducts();
    }
  }

  loadAllUsers(): void {
    this.adminService.getAllUsers().subscribe({
      next: (users) => {
        this.allUsers = users.filter((u: any) => !u.is_deleted || u.is_deleted === 0);
        this.filteredUsers = [...this.allUsers];
      },
      error: (err) => console.error('Error loading users:', err)
    });
  }

  loadAllOrders(): void {
    this.adminService.getRecentOrders().subscribe({
      next: (orders) => {
        this.allOrders = orders;
        this.filteredOrders = [...this.allOrders];
      },
      error: (err) => console.error('Error loading orders:', err)
    });
  }

  loadAllReviews(): void {
    this.adminService.getReviewsWithDetails().subscribe({
      next: (reviews) => {
        this.reviews = reviews;
        this.filteredReviews = [...this.reviews];
      },
      error: (err) => console.error('Error loading reviews:', err)
    });
  }

  loadAllProducts(): void {
    console.log('📦 Loading all products...');
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        console.log('✅ Products loaded:', products);
        this.products = products;
        this.filteredProducts = [...this.products];
      },
      error: (err) => console.error('❌ Error loading products:', err)
    });
  }

  // Filter functions
  filterUsers(): void {
    const query = this.userSearchQuery.toLowerCase().trim();
    if (!query) {
      this.filteredUsers = [...this.allUsers];
    } else {
      this.filteredUsers = this.allUsers.filter(u =>
        u.username?.toLowerCase().includes(query) ||
        u.email?.toLowerCase().includes(query)
      );
    }
  }

  filterOrders(): void {
    let filtered = [...this.allOrders];
    
    if (this.orderStatusFilter !== 'all') {
      filtered = filtered.filter(o => o.status?.toLowerCase() === this.orderStatusFilter.toLowerCase());
    }
    
    const query = this.orderSearchQuery.toLowerCase().trim();
    if (query) {
      filtered = filtered.filter(o =>
        o.id.toString().includes(query) ||
        o.username?.toLowerCase().includes(query)
      );
    }
    
    this.filteredOrders = filtered;
  }

  filterReviews(): void {
    const query = this.reviewSearchQuery.toLowerCase().trim();
    if (!query) {
      this.filteredReviews = [...this.reviews];
    } else {
      this.filteredReviews = this.reviews.filter(r =>
        r.productName?.toLowerCase().includes(query) ||
        r.username?.toLowerCase().includes(query) ||
        r.comment?.toLowerCase().includes(query)
      );
    }
  }

  filterProducts(): void {
    const query = this.productSearchQuery.toLowerCase().trim();
    if (!query) {
      this.filteredProducts = [...this.products];
    } else {
      this.filteredProducts = this.products.filter(p =>
        p.name?.toLowerCase().includes(query)
      );
    }
  }

  // Product Management Functions
  openAddProductForm(): void {
    console.log('➕ Opening add product form');
    this.editingProduct = false;
    this.productForm = {
      id: 0,
      categoryId: 1,
      brandId: 1,
      name: '',
      description: '',
      price: 0,
      stock: 0,
      imageUrl: ''
    };
    this.showProductForm = true;
  }

  openEditProductForm(product: Product): void {
    console.log('✏️ Opening edit product form for:', product);
    this.editingProduct = true;
    this.productForm = {
      id: product.id || 0,
      categoryId: typeof product.categoryId === 'object' ? product.categoryId.id : (product.categoryId || 1),
      brandId: typeof product.brandId === 'object' ? product.brandId.id : (product.brandId || 1),
      name: product.name || '',
      description: product.description || '',
      price: product.price || 0,
      stock: product.stock || 0,
      imageUrl: product.imageUrl || ''
    };
    this.showProductForm = true;
  }

  closeProductForm(): void {
    console.log('❌ Closing product form');
    this.showProductForm = false;
    this.editingProduct = false;
  }

  saveProduct(): void {
    console.log('💾 Saving product...', this.productForm);
    
    if (!this.productForm.name || this.productForm.price <= 0) {
      alert('Kérlek töltsd ki az összes kötelező mezőt!');
      return;
    }

    const productData = {
      categoryId: this.productForm.categoryId,
      brandId: this.productForm.brandId,
      name: this.productForm.name,
      description: this.productForm.description,
      price: this.productForm.price,
      stock: this.productForm.stock,
      imageUrl: this.productForm.imageUrl
    };

    console.log('📤 Product data to send:', productData);

    if (this.editingProduct) {
      // Update existing product - use productService
      console.log('🔄 Updating product with ID:', this.productForm.id);
      this.productService.updateProduct(this.productForm.id, productData).subscribe({
        next: (response) => {
          console.log('✅ Product updated:', response);
          alert('Termék sikeresen frissítve!');
          this.closeProductForm();
          this.loadAllProducts();
        },
        error: (err) => {
          console.error('❌ Error updating product:', err);
          alert('Hiba történt a termék frissítése során: ' + (err.error?.message || err.message));
        }
      });
    } else {
      // Create new product - use productService
      console.log('➕ Creating new product');
      this.productService.createProduct(productData).subscribe({
        next: (response) => {
          console.log('✅ Product created:', response);
          alert('Termék sikeresen létrehozva!');
          this.closeProductForm();
          this.loadAllProducts();
        },
        error: (err) => {
          console.error('❌ Error creating product:', err);
          alert('Hiba történt a termék létrehozása során: ' + (err.error?.message || err.message));
        }
      });
    }
  }

  deleteProduct(productId: number): void {
    console.log('🗑️ Delete product requested for ID:', productId);
    
    if (!confirm('Biztosan törölni szeretnéd ezt a terméket?')) {
      console.log('❌ Delete cancelled by user');
      return;
    }

    console.log('🔄 Deleting product...');
    this.productService.deleteProduct(productId).subscribe({
      next: (response) => {
        console.log('✅ Product deleted:', response);
        alert('Termék sikeresen törölve!');
        this.loadAllProducts();
      },
      error: (err) => {
        console.error('❌ Error deleting product:', err);
        alert('Hiba történt a termék törlése során: ' + (err.error?.message || err.message));
      }
    });
  }

  // Formatting functions
  formatPrice(price: number): string {
    if (price >= 1000000) {
      return (price / 1000000).toFixed(2) + 'M Ft';
    } else if (price >= 1000) {
      return (price / 1000).toFixed(2) + 'K Ft';
    }
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  formatFullPrice(price: number): string {
    return Math.round(price).toLocaleString('hu-HU') + ' Ft';
  }

  formatNumber(num: number): string {
    return num.toLocaleString('hu-HU');
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return `${date.getFullYear()}.${String(date.getMonth() + 1).padStart(2, '0')}.${String(date.getDate()).padStart(2, '0')}.`;
  }

  getStatusClass(status: string): string {
    if (!status) return '';
    switch (status.toLowerCase()) {
      case 'completed':
      case 'shipped':
      case 'delivered':
        return 'status-completed';
      case 'shipping':
        return 'status-shipping';
      case 'processing':
      case 'pending':
        return 'status-processing';
      case 'cancelled':
        return 'status-cancelled';
      default:
        return '';
    }
  }

  getStatusText(status: string): string {
    if (!status) return 'Ismeretlen';
    switch (status.toLowerCase()) {
      case 'completed': return 'Teljesítve';
      case 'shipped': return 'Kiszállítva';
      case 'delivered': return 'Kézbesítve';
      case 'shipping': return 'Szállítás alatt';
      case 'processing': return 'Feldolgozás';
      case 'pending': return 'Függőben';
      case 'cancelled': return 'Törölve';
      default: return status;
    }
  }

  getRoleClass(role: string): string {
    return role?.toLowerCase() === 'admin' ? 'role-admin' : 'role-customer';
  }

  getRoleText(role: string): string {
    return role?.toLowerCase() === 'admin' ? 'Admin' : 'Vásárló';
  }

  getChartBarHeight(value: number): number {
    const max = Math.max(...this.chartData.map(d => d.sales), 1);
    return (value / max) * 100;
  }

  getOrdersBarHeight(value: number): number {
    const max = Math.max(...this.chartData.map(d => d.orders), 1);
    return (value / max) * 100;
  }

  getRatingStars(rating: number): string {
    return '★'.repeat(rating) + '☆'.repeat(5 - rating);
  }

  getStock(product: any): number {
    return product?.stock ?? 0;
  }

  goBack(): void {
    this.router.navigate(['/profile']);
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/mainpage']);
  }
}