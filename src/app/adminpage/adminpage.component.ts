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

  // Notification state
  showSuccessNotification: boolean = false;
  showErrorNotification: boolean = false;
  successMessage: string = '';
  errorMessage: string = '';

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
    pPrice: 0,
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
    const user = this.authService.getCurrentUser();
    if (!user || user.role?.toLowerCase() !== 'admin') {
      this.router.navigate(['/mainpage']);
      return;
    }

    const now = new Date();
    const days = ['vasárnap', 'hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat'];
    this.today = `${now.getFullYear()}. ${String(now.getMonth() + 1).padStart(2, '0')}. ${String(now.getDate()).padStart(2, '0')}. ${days[now.getDay()]}`;

    this.loadDashboardData();
  }

  // ==================== DASHBOARD ====================

  loadDashboardData(): void {
    this.loading = true;

    this.adminService.getUserCount().subscribe({
      next: (count) => { this.stats.users = count; },
      error: (err) => console.error('❌ Error loading user count:', err)
    });

    this.loadAdmins();
    this.loadChartData();
    this.loadRecentOrders();
    this.loadTopProducts();
    this.loadStats();

    this.loading = false;
  }

  loadStats(): void {
    this.adminService.getTotalRevenue().subscribe({
      next: (response) => { this.stats.revenue = response.totalRevenue || 0; },
      error: (err) => console.error('❌ Error loading revenue:', err)
    });

    this.adminService.getTotalProfit().subscribe({
      next: (response) => { this.stats.profit = response.totalProfit || 0; },
      error: (err) => console.error('❌ Error loading profit:', err)
    });

    this.adminService.getOrdersCount().subscribe({
      next: (response) => { this.stats.orders = response.totalOrders || 0; },
      error: (err) => console.error('❌ Error loading orders:', err)
    });
  }

  loadAdmins(): void {
    this.adminService.getAdminUsers().subscribe({
      next: (admins) => {
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
      next: (data) => { this.chartData = data; },
      error: (err) => console.error('❌ Error loading chart data:', err)
    });
  }

  loadRecentOrders(): void {
    this.adminService.getRecentOrders().subscribe({
      next: (orders) => { this.recentOrders = orders.slice(0, 5); },
      error: (err) => console.error('❌ Error loading recent orders:', err)
    });
  }

  loadTopProducts(): void {
    this.adminService.getTopProducts().subscribe({
      next: (products) => { this.topProducts = products; },
      error: (err) => console.error('❌ Error loading top products:', err)
    });
  }

  // ==================== NAVIGATION ====================

  setActiveMenu(menu: string): void {
    this.activeMenu = menu;

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

  // ==================== USERS ====================

  loadAllUsers(): void {
    this.adminService.getAllUsers().subscribe({
      next: (users) => {
        this.allUsers = users.filter((u: any) => !u.is_deleted || u.is_deleted === 0);
        this.filteredUsers = [...this.allUsers];
      },
      error: (err) => console.error('Error loading users:', err)
    });
  }

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

  softDeleteUser(userId: number, username: string): void {

    this.adminService.softDeleteUser(userId).subscribe({
      next: () => {
        this.showSuccess(`"${username}" felhasználó sikeresen törölve!`);
        this.loadAllUsers();
      },
      error: (err) => {
        console.error('❌ Error soft-deleting user:', err);
        this.showError('Hiba történt a törlés során: ' + (err.error?.message || err.message));
      }
    });
  }

  // ==================== ORDERS ====================

  loadAllOrders(): void {
    this.adminService.getAllOrdersWithUsernames().subscribe({
      next: (orders) => {
        this.allOrders = orders;
        this.filterOrders();
      },
      error: (err) => console.error('Error loading orders:', err)
    });
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

  cancelOrder(orderId: number): void {

    this.adminService.cancelOrder(orderId).subscribe({
      next: () => {
        this.showSuccess(`#${orderId} rendelés sikeresen lemondva!`);
        this.loadAllOrders();
      },
      error: (err) => {
        console.error('❌ Error cancelling order:', err);
        this.showError('Hiba történt a rendelés lemondásakor: ' + (err.error?.message || err.message));
      }
    });
  }

  canCancelOrder(status: string): boolean {
    const nonCancellable = ['completed', 'shipped', 'delivered', 'cancelled'];
    return !nonCancellable.includes(status?.toLowerCase());
  }

  // ==================== REVIEWS ====================

  loadAllReviews(): void {
    this.adminService.getReviewsWithDetails().subscribe({
      next: (reviews) => {
        this.reviews = reviews;
        this.filteredReviews = [...this.reviews];
      },
      error: (err) => console.error('Error loading reviews:', err)
    });
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

  // ==================== PRODUCTS ====================

  loadAllProducts(): void {
    this.productService.getAllProducts().subscribe({
      next: (products) => {
        this.products = products;
        this.filteredProducts = [...this.products];
      },
      error: (err) => console.error('❌ Error loading products:', err)
    });
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

  openAddProductForm(): void {
    this.editingProduct = false;
    this.productForm = {
      id: 0,
      categoryId: 1,
      brandId: 1,
      name: '',
      description: '',
      price: 0,
      pPrice: 0,
      stock: 0,
      imageUrl: ''
    };
    this.showProductForm = true;
  }

  openEditProductForm(product: Product): void {
    this.editingProduct = true;
    this.productForm = {
      id: product.id || 0,
      categoryId: typeof product.categoryId === 'object' ? product.categoryId.id : (product.categoryId || 1),
      brandId: typeof product.brandId === 'object' ? product.brandId.id : (product.brandId || 1),
      name: product.name || '',
      description: product.description || '',
      price: product.price || 0,
      pPrice: product.pPrice || 0,
      stock: product.stock || 0,
      imageUrl: product.imageUrl || ''
    };
    this.showProductForm = true;
  }

  closeProductForm(): void {
    this.showProductForm = false;
    this.editingProduct = false;
  }

  saveProduct(): void {
    if (!this.productForm.name || this.productForm.price <= 0) {
      this.showError('Kérlek töltsd ki az összes kötelező mezőt!');
      return;
    }

    const productData = {
      categoryId: this.productForm.categoryId,
      brandId: this.productForm.brandId,
      name: this.productForm.name,
      description: this.productForm.description,
      price: this.productForm.price,
      pPrice: this.productForm.pPrice,
      stock: this.productForm.stock,
      imageUrl: this.productForm.imageUrl
    };

    if (this.editingProduct) {
      this.productService.updateProduct(this.productForm.id, productData).subscribe({
        next: () => {
          this.showSuccess('Termék sikeresen frissítve!');
          this.closeProductForm();
          this.loadAllProducts();
        },
        error: (err) => {
          this.showError('Hiba történt a termék frissítése során: ' + (err.error?.message || err.message));
        }
      });
    } else {
      this.productService.createProduct(productData).subscribe({
        next: () => {
          this.showSuccess('Termék sikeresen létrehozva!');
          this.closeProductForm();
          this.loadAllProducts();
        },
        error: (err) => {
          const errorMsg = err.error?.message || err.message || 'Ismeretlen hiba';
          this.showError('Hiba történt a termék létrehozása során: ' + errorMsg);
        }
      });
    }
  }

  deleteProduct(productId: number): void {
    

    this.productService.deleteProduct(productId).subscribe({
      next: () => {
        this.showSuccess('Termék sikeresen törölve!');
        this.loadAllProducts();
      },
      error: (err) => {
        this.showError('Hiba történt a termék törlése során: ' + (err.error?.message || err.message));
      }
    });
  }

  // ==================== FORMATTING ====================

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
      case 'delivered':  return 'status-completed';
      case 'shipping':   return 'status-shipping';
      case 'processing':
      case 'pending':    return 'status-processing';
      case 'cancelled':  return 'status-cancelled';
      default:           return '';
    }
  }

  getStatusText(status: string): string {
    if (!status) return 'Ismeretlen';
    switch (status.toLowerCase()) {
      case 'completed':  return 'Teljesítve';
      case 'shipped':    return 'Kiszállítva';
      case 'delivered':  return 'Kézbesítve';
      case 'shipping':   return 'Szállítás alatt';
      case 'processing': return 'Feldolgozás';
      case 'pending':    return 'Függőben';
      case 'cancelled':  return 'Törölve';
      default:           return status;
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

  // ==================== NOTIFICATIONS ====================

  private showSuccess(message: string, duration: number = 2000): void {
    this.successMessage = message;
    this.showSuccessNotification = true;
    setTimeout(() => { this.showSuccessNotification = false; }, duration);
  }

  private showError(message: string, duration: number = 3000): void {
    this.errorMessage = message;
    this.showErrorNotification = true;
    setTimeout(() => { this.showErrorNotification = false; }, duration);
  }
}