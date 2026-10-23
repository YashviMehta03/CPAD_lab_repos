import React, { useState } from 'react';
import {
  SafeAreaView,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Alert,
  StatusBar,
} from 'react-native';

// ─────────────────────────────────────────────
// Widget 1 – SummaryCard
// Shows total balance, total income and total expense
// ─────────────────────────────────────────────
function SummaryCard({ balance, income, expense }) {
  return (
    <View style={styles.summaryCard}>
      <Text style={styles.summaryTitle}>Total Balance</Text>
      <Text style={styles.balanceAmount}>₹ {balance.toFixed(2)}</Text>
      <View style={styles.summaryRow}>
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>Income</Text>
          <Text style={[styles.summaryValue, styles.incomeColor]}>
            ₹ {income.toFixed(2)}
          </Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryItem}>
          <Text style={styles.summaryLabel}>Expense</Text>
          <Text style={[styles.summaryValue, styles.expenseColor]}>
            ₹ {expense.toFixed(2)}
          </Text>
        </View>
      </View>
    </View>
  );
}

// ─────────────────────────────────────────────
// Widget 2 – CategoryChip
// Selectable category button (Food, Travel, etc.)
// Highlights when selected using conditional styling
// ─────────────────────────────────────────────
function CategoryChip({ label, selected, onPress }) {
  return (
    <TouchableOpacity
      style={[styles.chip, selected && styles.chipSelected]}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={`Category ${label}`}
    >
      <Text style={[styles.chipText, selected && styles.chipTextSelected]}>
        {label}
      </Text>
    </TouchableOpacity>
  );
}

const CATEGORIES = ['Food', 'Travel', 'Shopping', 'Bills', 'Salary', 'Other'];

// ─────────────────────────────────────────────
// Widget 3 – AddForm
// Form to enter title, amount, type and category
// Holds its own local state for the input fields
// ─────────────────────────────────────────────
function AddForm({ onAdd }) {
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [type, setType] = useState('Expense'); // 'Income' | 'Expense'
  const [category, setCategory] = useState('Other');

  const handleSubmit = () => {
    // Validate: title must not be empty, amount must be a positive number
    if (!title.trim()) {
      Alert.alert('Invalid input', 'Please enter a title.');
      return;
    }
    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
      Alert.alert('Invalid input', 'Please enter a valid positive amount.');
      return;
    }

    // Create transaction object with unique id
    const newTransaction = {
      id: Date.now().toString(),
      title: title.trim(),
      amount: parsedAmount,
      type,
      category,
    };

    onAdd(newTransaction);

    // Reset fields
    setTitle('');
    setAmount('');
    setType('Expense');
    setCategory('Other');
  };

  return (
    <View style={styles.formCard}>
      <Text style={styles.formTitle}>Add Transaction</Text>

      {/* Type Toggle */}
      <View style={styles.typeRow}>
        <TouchableOpacity
          style={[styles.typeBtn, type === 'Income' && styles.typeBtnIncome]}
          onPress={() => setType('Income')}
          accessibilityRole="button"
          accessibilityLabel="Select Income"
        >
          <Text style={[styles.typeBtnText, type === 'Income' && styles.typeBtnTextActive]}>
            + Income
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.typeBtn, type === 'Expense' && styles.typeBtnExpense]}
          onPress={() => setType('Expense')}
          accessibilityRole="button"
          accessibilityLabel="Select Expense"
        >
          <Text style={[styles.typeBtnText, type === 'Expense' && styles.typeBtnTextActive]}>
            - Expense
          </Text>
        </TouchableOpacity>
      </View>

      {/* Title Input */}
      <TextInput
        style={styles.input}
        placeholder="Title (e.g. Lunch, Salary)"
        placeholderTextColor="#999"
        value={title}
        onChangeText={setTitle}
        accessibilityLabel="Transaction title"
      />

      {/* Amount Input */}
      <TextInput
        style={styles.input}
        placeholder="Amount (e.g. 250)"
        placeholderTextColor="#999"
        keyboardType="numeric"
        value={amount}
        onChangeText={setAmount}
        accessibilityLabel="Transaction amount"
      />

      {/* Category Chips */}
      <Text style={styles.categoryLabel}>Category</Text>
      <View style={styles.chipsRow}>
        {CATEGORIES.map((cat) => (
          <CategoryChip
            key={cat}
            label={cat}
            selected={category === cat}
            onPress={() => setCategory(cat)}
          />
        ))}
      </View>

      {/* Submit Button */}
      <TouchableOpacity
        style={styles.addButton}
        onPress={handleSubmit}
        accessibilityRole="button"
        accessibilityLabel="Add Transaction"
      >
        <Text style={styles.addButtonText}>Add Transaction</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─────────────────────────────────────────────
// Widget 4 – TransactionItem
// One row in the list showing amount, category and a delete button
// Receives transaction data and delete callback as props
// ─────────────────────────────────────────────
function TransactionItem({ item, onDelete }) {
  const isIncome = item.type === 'Income';
  return (
    <View style={styles.transactionItem}>
      <View style={[styles.typeIndicator, isIncome ? styles.incomeIndicator : styles.expenseIndicator]} />
      <View style={styles.transactionInfo}>
        <Text style={styles.transactionTitle}>{item.title}</Text>
        <Text style={styles.transactionCategory}>{item.category}</Text>
      </View>
      <Text style={[styles.transactionAmount, isIncome ? styles.incomeColor : styles.expenseColor]}>
        {isIncome ? '+' : '-'} ₹{item.amount.toFixed(2)}
      </Text>
      <TouchableOpacity
        style={styles.deleteButton}
        onPress={() => onDelete(item.id)}
        accessibilityRole="button"
        accessibilityLabel={`Delete ${item.title}`}
      >
        <Text style={styles.deleteButtonText}>✕</Text>
      </TouchableOpacity>
    </View>
  );
}

// ─────────────────────────────────────────────
// Widget 5 – App (Root Widget)
// Holds state (transactions array) and connects all widgets
// Income & expense totals calculated from state on every render
// ─────────────────────────────────────────────
export default function App() {
  const [transactions, setTransactions] = useState([]);

  // Add a new transaction (called from AddForm via props/callback)
  const addTransaction = (transaction) => {
    setTransactions((prev) => [transaction, ...prev]);
  };

  // Delete a transaction by id (called from TransactionItem via props/callback)
  const deleteTransaction = (id) => {
    setTransactions((prev) => prev.filter((t) => t.id !== id));
  };

  // Calculate totals on every render using filter() and reduce()
  const income = transactions
    .filter((t) => t.type === 'Income')
    .reduce((sum, t) => sum + t.amount, 0);

  const expense = transactions
    .filter((t) => t.type === 'Expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const balance = income - expense;

  // Header: SummaryCard + AddForm (scrolls with the list)
  const ListHeader = () => (
    <>
      <SummaryCard balance={balance} income={income} expense={expense} />
      <AddForm onAdd={addTransaction} />
      <Text style={styles.historyTitle}>Transaction History</Text>
    </>
  );

  // Shown when the list is empty
  const ListEmpty = () => (
    <View style={styles.emptyContainer}>
      <Text style={styles.emptyText}>No transactions yet.</Text>
      <Text style={styles.emptySubText}>Add an income or expense above.</Text>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor="#1a1a2e" />

      {/* App Header */}
      <View style={styles.appHeader}>
        <Text style={styles.appHeaderText}>💰 Expense Manager</Text>
      </View>

      {/* FlatList renders the transaction list efficiently.
          The summary card and form are placed in ListHeaderComponent
          so the whole screen scrolls together. */}
      <FlatList
        data={transactions}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TransactionItem item={item} onDelete={deleteTransaction} />
        )}
        ListHeaderComponent={<ListHeader />}
        ListEmptyComponent={<ListEmpty />}
        contentContainerStyle={styles.listContent}
        showsVerticalScrollIndicator={false}
      />
    </SafeAreaView>
  );
}

// ─────────────────────────────────────────────
// StyleSheet
// Flexbox layout; green for income, red for expense
// ─────────────────────────────────────────────
const COLORS = {
  background: '#1a1a2e',
  surface: '#16213e',
  card: '#0f3460',
  accent: '#e94560',
  income: '#2ecc71',
  expense: '#e74c3c',
  text: '#ecf0f1',
  textSecondary: '#bdc3c7',
  border: '#2c3e50',
  chipBg: '#1e2d45',
};

const styles = StyleSheet.create({
  // Root
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  listContent: {
    paddingBottom: 30,
  },

  // App Header
  appHeader: {
    backgroundColor: COLORS.surface,
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  appHeaderText: {
    color: COLORS.text,
    fontSize: 20,
    fontWeight: '700',
    letterSpacing: 0.5,
  },

  // SummaryCard
  summaryCard: {
    margin: 16,
    padding: 20,
    backgroundColor: COLORS.card,
    borderRadius: 16,
    alignItems: 'center',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 4,
  },
  summaryTitle: {
    color: COLORS.textSecondary,
    fontSize: 14,
    marginBottom: 6,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  balanceAmount: {
    color: COLORS.text,
    fontSize: 36,
    fontWeight: '800',
    marginBottom: 20,
  },
  summaryRow: {
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-around',
  },
  summaryItem: {
    alignItems: 'center',
    flex: 1,
  },
  divider: {
    width: 1,
    backgroundColor: COLORS.border,
  },
  summaryLabel: {
    color: COLORS.textSecondary,
    fontSize: 13,
    marginBottom: 4,
  },
  summaryValue: {
    fontSize: 18,
    fontWeight: '700',
  },
  incomeColor: {
    color: COLORS.income,
  },
  expenseColor: {
    color: COLORS.expense,
  },

  // AddForm
  formCard: {
    marginHorizontal: 16,
    marginBottom: 12,
    padding: 16,
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.2,
    shadowRadius: 3,
  },
  formTitle: {
    color: COLORS.text,
    fontSize: 17,
    fontWeight: '700',
    marginBottom: 14,
  },
  typeRow: {
    flexDirection: 'row',
    marginBottom: 14,
    gap: 10,
  },
  typeBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 10,
    alignItems: 'center',
    backgroundColor: COLORS.chipBg,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  typeBtnIncome: {
    backgroundColor: '#1a4d2e',
    borderColor: COLORS.income,
  },
  typeBtnExpense: {
    backgroundColor: '#4d1a1a',
    borderColor: COLORS.expense,
  },
  typeBtnText: {
    color: COLORS.textSecondary,
    fontWeight: '600',
    fontSize: 14,
  },
  typeBtnTextActive: {
    color: COLORS.text,
  },
  input: {
    backgroundColor: COLORS.chipBg,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 11,
    color: COLORS.text,
    fontSize: 15,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  categoryLabel: {
    color: COLORS.textSecondary,
    fontSize: 13,
    marginBottom: 8,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
  },
  chipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },

  // CategoryChip
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 20,
    backgroundColor: COLORS.chipBg,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  chipSelected: {
    backgroundColor: COLORS.accent,
    borderColor: COLORS.accent,
  },
  chipText: {
    color: COLORS.textSecondary,
    fontSize: 13,
    fontWeight: '500',
  },
  chipTextSelected: {
    color: '#fff',
    fontWeight: '700',
  },

  // Add Button
  addButton: {
    backgroundColor: COLORS.accent,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
    elevation: 2,
    shadowColor: COLORS.accent,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.4,
    shadowRadius: 4,
  },
  addButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.5,
  },

  // History Title
  historyTitle: {
    color: COLORS.textSecondary,
    fontSize: 13,
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginHorizontal: 20,
    marginBottom: 8,
  },

  // TransactionItem
  transactionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    marginBottom: 8,
    padding: 14,
    backgroundColor: COLORS.surface,
    borderRadius: 12,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.15,
    shadowRadius: 2,
  },
  typeIndicator: {
    width: 4,
    height: 36,
    borderRadius: 2,
    marginRight: 12,
  },
  incomeIndicator: {
    backgroundColor: COLORS.income,
  },
  expenseIndicator: {
    backgroundColor: COLORS.expense,
  },
  transactionInfo: {
    flex: 1,
  },
  transactionTitle: {
    color: COLORS.text,
    fontSize: 15,
    fontWeight: '600',
  },
  transactionCategory: {
    color: COLORS.textSecondary,
    fontSize: 12,
    marginTop: 2,
  },
  transactionAmount: {
    fontSize: 15,
    fontWeight: '700',
    marginRight: 12,
  },
  deleteButton: {
    backgroundColor: '#3d1a1a',
    borderRadius: 8,
    width: 30,
    height: 30,
    alignItems: 'center',
    justifyContent: 'center',
  },
  deleteButtonText: {
    color: COLORS.expense,
    fontSize: 13,
    fontWeight: '700',
  },

  // Empty State
  emptyContainer: {
    alignItems: 'center',
    marginTop: 30,
    paddingHorizontal: 20,
  },
  emptyText: {
    color: COLORS.textSecondary,
    fontSize: 16,
    fontWeight: '600',
  },
  emptySubText: {
    color: COLORS.border,
    fontSize: 13,
    marginTop: 6,
  },
});
