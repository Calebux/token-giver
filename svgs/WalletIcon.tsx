const WalletIcon = ({
  width = "1.2em",
  height = "1.2em",
}: {
  width?: string;
  height?: string;
}) => {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width={width}
      height={height}
      viewBox="0 0 256 256"
    >
      <path
        fill="currentColor"
        d="M216 64H56a8 8 0 0 1 0-16h136a8 8 0 0 0 0-16H56a24 24 0 0 0-24 24v128a24 24 0 0 0 24 24h160a16 16 0 0 0 16-16V80a16 16 0 0 0-16-16m0 128H56a8 8 0 0 1-8-8V78.63A23.8 23.8 0 0 0 56 80h160Zm-48-60a12 12 0 1 1 12 12a12 12 0 0 1-12-12"
      />
    </svg>
  );
};

export default WalletIcon;